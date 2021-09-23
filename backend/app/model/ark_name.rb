class ArkName < Sequel::Model(:ark_name)
  include ASModel
  corresponds_to JSONModel(:ark_name)

  set_model_scope :global

  @minters ||= {}

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
      self
        .filter(fk_col => obj.id, :is_current => 1)
        .update(:is_current => 0,
                :user_value => nil,
                :retired_at_epoch_ms => (now.to_f * 1000).to_i)

      ark_minter.mint!(obj, external_ark_url,
                       fk_col => obj.id,
                       :created_by => 'admin',
                       :last_modified_by => 'admin',
                       :create_time => now,
                       :system_mtime => now,
                       :user_mtime => now,
                       :is_current => 1,
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

    # Make sure the value we've generated hasn't been used elsewhere.
    db[:ark_uniq_check].filter(:record_uri => obj.uri).delete
    generated_values = self.filter(fk_col => obj.id).select(:generated_value).distinct.map {|row| row[:generated_value]}

    begin
      generated_values.each do |value|
        db[:ark_uniq_check].insert(:record_uri => obj.uri, :generated_value => value)
      end
    rescue Sequel::UniqueConstraintViolation => e
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
      :version_key => ark_minter.version_key_for(obj)
    }

    DB.open do |db|
      current_ark = ArkName.first(fk_col => obj.id, :is_current => 1)

      ArkName.filter(fk_col => obj.id).delete

      if ark_name['current']
        generated_value, user_value = calculate_values(ark_name['current'], current_ark)

        ArkName.insert(ark.merge(:generated_value => generated_value,
                                 :user_value => user_value,
                                 :is_current => 1,
                                 :retired_at_epoch_ms => 0))
      end

      now_i = (now.to_f * 1000).to_i

      ark_name['previous'].each_with_index do |prev, ix|
        generated_value, user_value = calculate_values(prev)

        ArkName.insert(ark.merge(:generated_value => generated_value,
                                 :user_value => user_value,
                                 :is_current => 0,
                                 :retired_at_epoch_ms => (now_i - ix)))
      end
    end

    check_unique(db, obj)

    true
  end

  # return generated_value and user_value column values for an ark_name based on these rules:
  #  - blow up if the value is not a valid ark
  #  - if `:arks_allow_external_arks` is true and this is a current_ark and the value is unchanged
  #      then no change is applied to generated_value or user_value (prefix is always snipped off)
  #  - in all other cases treat value as a generated_value
  def self.calculate_values(value, current_ark = nil)
    unless value.match(/^(.*?\/)?ark:\//)
      raise JSONModel::ValidationException.new(:errors => {"ark" => ["ark_format_error"]})
    end

    # [generated_value, user_value]
    if AppConfig[:arks_allow_external_arks] && current_ark && value == current_ark[:user_value]
      [current_ark[:generated_value].sub(/^(.*?\/)?ark:\//, 'ark:/'), value]
    else
      [value.sub(/^(.*?\/)?ark:\//, 'ark:/'), nil]
    end
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
    if AppConfig[:arks_allow_external_arks] && self.user_value
      self.user_value
    else
      self.class.prefix(self.generated_value)
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

    return true if AppConfig[:arks_allow_external_arks] && current.user_value.to_s != external_ark_url.to_s

    minter = self.ark_minter

    !minter.is_still_current?(current, obj)
  end
end
