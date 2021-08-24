class ArkName < Sequel::Model(:ark_name)
  include ASModel
  corresponds_to JSONModel(:ark_name)

  set_model_scope :global

  one_to_one :resource

  # validations:
  # must be linked to a resource or archival object
  # cannot link to more than one type of resource
  # can't have more than one ark_id point to the same resource or archival object

  def validate
    validate_resources_defined
    validates_unique(:resource_id, :message => "ARK must point to a unique Resource")
    validates_unique(:archival_object_id, :message => "ARK must point to a unique Archival Object")
    super
  end

  def validate_resources_defined
    resources_defined = 0
    resources_defined += 1 unless self.resource_id.nil?
    resources_defined += 1 unless self.archival_object_id.nil?

    unless resources_defined == 1
      errors.add(:base, 'Exactly one of [resource_id, archival_object_id] must be defined.')
    end
  end

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

    self
      .filter(fk_col => obj.id, :is_current => 1)
      .update(:is_current => 0,
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
  end

  def self.handle_delete(model_clz, ids)
    ArkName.filter(fk_for_class(model_clz) => ids).delete
  end

  def self.prefix(value)
    "#{AppConfig[:ark_url_prefix]}/#{value}"
  end

  def value
    self.user_value || self.class.prefix(self.generated_value)
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

    # FIXME: only if we're running in a mode that allows user values
    # the user value has changed, mint a new ark
    return true if current.user_value.to_s != json['external_ark_url'].to_s

    # no changes required
    false
  end
end
