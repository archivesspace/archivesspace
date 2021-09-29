class ArkName < Sequel::Model(:ark_name)
  include ASModel
  corresponds_to JSONModel(:ark_name)

  set_model_scope :global

  @minters ||= {}

  EXTERNAL_ARK_VERSION_KEY = '__archivesspace_external_url'

  def self.register_minter(minter_id, clz)
    @minters[minter_id] = clz
    nil
  end

  def self.load_minter(minter_id)
    clz = @minters.fetch(minter_id) do
      raise "Couldn't find a minter matching: #{minter_id}"
    end

    clz.new
  end

  def self.ark_minter
    load_minter(AppConfig[:ark_minter])
  end

  def self.ensure_ark_for_record(obj, external_ark_url)
    return false unless AppConfig[:arks_enabled]
    return false unless ArkName.require_update?(obj, external_ark_url)

    fk_col = fk_for_class(obj.class)

    return false unless fk_col

    now = Time.now

    DB.open do |db|
      # Handle the case where external ARKs are enabled
      if AppConfig[:arks_allow_external_arks]
        self.filter(fk_col => obj.id, :is_external_url => 1).delete

        # ... and we have one coming in
        if external_ark_url
          self
            .filter(fk_col => obj.id, :is_current => 1)
            .update(:is_current => 0,
                    :retired_at_epoch_ms => (now.to_f * 1000).to_i)

          self.insert(fk_col => obj.id,
                      :created_by => 'admin',
                      :last_modified_by => 'admin',
                      :create_time => now,
                      :system_mtime => now,
                      :user_mtime => now,
                      :is_current => 1,
                      :is_external_url => 1,
                      :retired_at_epoch_ms => 0,
                      :lock_version => 0,
                      :version_key => EXTERNAL_ARK_VERSION_KEY,
                      :ark_value => external_ark_url,
                     )

          check_unique(db, obj)
          return true
        end
      end

      # Look for a previously minted ARK that we can promote into current
      previous_ark = self
        .filter(fk_col => obj.id, :version_key => ark_minter.version_key_for(obj))
        .reverse(:retired_at_epoch_ms)
        .first

      if previous_ark
        self
          .filter(fk_col => obj.id, :is_current => 1)
          .update(:is_current => 0,
                  :retired_at_epoch_ms => (now.to_f * 1000).to_i)

        self.filter(:id => previous_ark.id).update(:is_current => 1, :retired_at_epoch_ms => 0)
        return
      end

      # Need to mint a new ARK
      self
        .filter(fk_col => obj.id, :is_current => 1)
        .update(:is_current => 0,
                :retired_at_epoch_ms => (now.to_f * 1000).to_i)

      ark_minter.mint!(obj,
                       fk_col => obj.id,
                       :created_by => 'admin',
                       :last_modified_by => 'admin',
                       :create_time => now,
                       :system_mtime => now,
                       :user_mtime => now,
                       :is_current => 1,
                       :is_external_url => 0,
                       :retired_at_epoch_ms => 0,
                       :lock_version => 0,
                       :version_key => ark_minter.version_key_for(obj),
                      )
    end

    check_unique(db, obj)

    true
  end

  def self.check_unique(db, obj)
    fk_col = fk_for_class(obj.class)
    return unless fk_col

    # Make sure the value we've generated, or the user value hasn't been used elsewhere.
    db[:ark_uniq_check].filter(:record_uri => obj.uri).delete

    ark_value_query = self.filter(fk_col => obj.id).select(:ark_value).distinct

    # If external ARKs are turned off, don't count them in our uniqueness checks
    unless AppConfig[:arks_allow_external_arks]
      ark_value_query = ark_value_query.filter(:is_external_url => 0)
    end

    begin
      ark_value_query.map {|row| row[:ark_value]}.each do |value|
        db[:ark_uniq_check].insert(:record_uri => obj.uri, :value => value.sub(/^.*?ark:/i, 'ark:'))
      end
    rescue Sequel::UniqueConstraintViolation => e
      # We want to give a useful error in the case that the collision is on the external_ark_url
      if our_external_ark = db[:ark_name].filter(fk_col => obj.id).filter(:is_external_url => 1).get(:ark_value)
        if db[:ark_name].filter(Sequel.~(fk_col => obj.id)).filter(:ark_value => our_external_ark).count > 0
          # Someone else collided with our external ARK url
          raise JSONModel::ValidationException.new(:errors => {"external_ark_url" => ["external_ark_collision"]})
        end
      end

      raise JSONModel::ValidationException.new(:errors => {"ark" => ["ark_collision"]})
    end
  end

  # Bypass the minting process and assert values for current and previous ARKs
  # Accepts an ASModel object for the record to apply the ARKs to and a
  # JSONModel(:ark_name) containing the asserted ARK values.
  # This supports the exceptional case where an admin is fixing spurious previous
  # ARKs, or is reconstructing a record and needs to assert its current ARK.
  def self.update_for_record(obj, ark_name)
    fk_col = fk_for_class(obj.class)
    raise "Record type does not support ARKs: #{obj.class}" unless fk_col
    now = Time.now

    ark = {
      fk_col => obj.id,
      :created_by => 'admin',
      :last_modified_by => 'admin',
      :create_time => now,
      :system_mtime => now,
      :user_mtime => now,
      :lock_version => 0,
    }

    DB.open do |db|
      current_ark = ArkName.first(fk_col => obj.id, :is_current => 1)

      ArkName.filter(fk_col => obj.id).delete

      if ark_name['current']
        if ark_name['current_is_external']
          ArkName.insert(ark.merge(:ark_value => ark_name['current'],
                                   :is_external_url => 1,
                                   :is_current => 1,
                                   :retired_at_epoch_ms => 0,
                                   :version_key => EXTERNAL_ARK_VERSION_KEY))
        else
          ArkName.insert(ark.merge(:ark_value => clean_ark_value(ark_name['current']),
                                   :is_external_url => 0,
                                   :is_current => 1,
                                   :retired_at_epoch_ms => 0,
                                   :version_key => ark_minter.version_key_for(obj)))
        end
      end

      now_i = (now.to_f * 1000).to_i

      ark_name['previous'].each_with_index do |prev, ix|
        ArkName.insert(ark.merge(:ark_value => clean_ark_value(prev),
                                 :is_current => 0,
                                 :is_external_url => 0,
                                 :retired_at_epoch_ms => (now_i - ix),
                                 :version_key => ark_minter.version_key_for(obj)))
      end
    end

    check_unique(db, obj)

    obj.class.update_mtime_for_ids([obj.id])

    true
  end

  def self.clean_ark_value(value)
    unless value.match(/^(.*?\/)?ark:\//)
      raise JSONModel::ValidationException.new(:errors => {"ark" => ["ark_format_error"]})
    end

    value.sub(/^(.*?\/)?ark:\//, 'ark:/')
  end


  # Invoked when the ARKs runner job kicks off.
  def self.run_housekeeping!
    DB.open do |db|
      # Delete any entries from our uniq check table whose records have since been
      # deleted/transferred.
      if DB.supports_mvcc?
        db[:ark_uniq_check]
          .join(:deleted_records, Sequel.qualify(:ark_uniq_check, :record_uri) => Sequel.qualify(:deleted_records, :uri))
          .delete
      else
        loop do
          to_delete = db[:ark_uniq_check]
                        .join(:deleted_records, Sequel.qualify(:ark_uniq_check, :record_uri) => Sequel.qualify(:deleted_records, :uri))
                        .select(Sequel.qualify(:ark_uniq_check, :record_uri))
                        .limit(256)
                        .map {|row| row[:record_uri]}

          break if to_delete.empty?

          db[:ark_uniq_check].filter(:record_uri => to_delete).delete
        end
      end
    end
  end

  def self.handle_delete(model_clz, ids)
    ArkName.filter(fk_for_class(model_clz) => ids).delete
  end

  def self.prefix(value)
    "#{AppConfig[:ark_url_prefix]}/#{value}"
  end

  def value
    if self.is_external_url == 1
      self.ark_value
    else
      self.class.prefix(self.ark_value)
    end
  end

  private

  def self.fk_for_class(clz)
    return nil unless clz.included_modules.include?(Arks)

    "#{clz.table_name}_id".intern
  end

  def self.require_update?(obj, external_ark_url)
    id_field = fk_for_class(obj.class)

    # record doesn't support arks
    return false unless id_field

    current = ArkName.filter(id_field => obj.id, :is_current => 1).first

    # record needs a current ark
    return true if current.nil?

    if AppConfig[:arks_allow_external_arks] && external_ark_url
      if current.ark_value.to_s == external_ark_url && current.is_external_url == 1
        return false
      end

      return true
    end

    minter = self.ark_minter

    !minter.is_still_current?(current, obj)
  end
end
