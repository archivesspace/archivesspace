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

  def self.ensure_ark_for_record(obj, json)
    return unless AppConfig[:arks_enabled]
    return unless ArkName.require_update?(obj, json)

    fk_col = fk_for_class(obj.class)

    return unless fk_col

    now = Time.now

    DB.open do |db|
      self
        .filter(fk_col => obj.id, :is_current => 1)
        .update(:is_current => 0,
                :user_value => nil,
                :retired_at_epoch_ms => (now.to_f * 1000).to_i)

      ark_minter.mint!(obj, json,
                       fk_col => obj.id,
                       :created_by => 'admin',
                       :last_modified_by => 'admin',
                       :create_time => now,
                       :system_mtime => now,
                       :user_mtime => now,
                       :is_current => 1,
                       :retired_at_epoch_ms => 0,
                       :lock_version => 0
                      )

      # Make sure the value we've generated hasn't been used elsewhere.
      db[:ark_uniq_check].filter(:record_uri => obj.uri).delete
      generated_values = self.filter(fk_col => obj.id).select(:generated_value).distinct.map {|row| row[:generated_value]}

      begin
        generated_values.each do |value|
          db[:ark_uniq_check].insert(:record_uri => obj.uri, :generated_value => value)
        end
      rescue Sequel::UniqueConstraintViolation
        raise JSONModel::ValidationException.new(:errors => {"ark" => ["ark_collision"]})
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

  def self.require_update?(obj, json)
    id_field = fk_for_class(obj.class)

    # record doesn't support arks
    return false unless id_field

    current = ArkName.filter(id_field => obj.id, :is_current => 1).first

    # record needs a current ark
    return true if current.nil?

    return true if AppConfig[:arks_allow_external_arks] && current.user_value.to_s != json['external_ark_url'].to_s

    minter = self.ark_minter

    !minter.is_still_current?(current, obj.repo_id)
  end
end
