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

    ark_id = self.insert(fk_col => obj.id,
                         :created_by => 'admin',
                         :last_modified_by => 'admin',
                         :create_time => now,
                         :system_mtime => now,
                         :user_mtime => now,
                         :is_current => 1,
                         :user_value => json['external_ark_url'],
                         :retired_at_epoch_ms => 0,
                         :lock_version => 0)

    self
      .filter(:id => ark_id)
      .update(:generated_value => build_generated_ark(ark_id))
  end

  def self.build_generated_ark(ark_id)
    "ark:/#{AppConfig[:ark_naan]}/#{ark_id}"
  end

  # NOTE: exporter calls this, but sequel_to_jsonmodel doesn't
  def self.get_ark_url(id, type)
    case type
    when :resource
      id_field = :resource_id
      klass_sym = :resource
    when :archival_object
      id_field = :archival_object_id
      klass_sym = :archival_object
    else
      return nil
    end

    external_url = get_external_ark_url(id, klass_sym)

    if !external_url.nil?
      return external_url
    else
      ark = ArkName.first(id_field => id)

      if !ark.nil?
        return "#{AppConfig[:ark_url_prefix]}/ark:/#{AppConfig[:ark_naan]}/#{ark.id}"
      else
        return nil
      end
    end
  end

  def self.handle_delete(model_clz, ids)
    ArkName.filter(fk_for_class(model_clz) => ids).delete
  end

  def self.prefix(value)
    "#{AppConfig[:ark_url_prefix]}/#{value}"
  end

  private

  # archival object or resource may have an external_ark_url defined.
  # query object to see. if found, find it and return it
  #
  # NOTE: exporter calls this, but sequel_to_jsonmodel doesn't
  def self.get_external_ark_url(id, type)
    case type
    when :resource
      klass = Resource
      table = "resource"
    when :archival_object
      klass = ArchivalObject
      table = "archival_object"
    else
      return nil
    end

    entity = klass.any_repo.filter(:id => id).first
    if entity.nil? || entity.external_ark_url.nil?
      return nil
    else
      return entity.external_ark_url
    end
  end

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

    # the user value has changed, mint a new ark
    return true if current.user_value.to_s != json['external_ark_url'].to_s

    # no changes required
    false
  end
end
