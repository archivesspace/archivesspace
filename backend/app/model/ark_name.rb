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

  def self.create_from_resource(resource)
    self.insert(:archival_object_id => nil,
                :resource_id        => resource.id,
                :created_by         => 'admin',
                :last_modified_by   => 'admin',
                :create_time        => Time.now,
                :system_mtime       => Time.now,
                :user_mtime         => Time.now,
                :lock_version       => 0)
  end

  def self.create_from_archival_object(archival_object)
    self.insert(:archival_object_id => archival_object.id,
                :resource_id        => nil,
                :created_by         => 'admin',
                :last_modified_by   => 'admin',
                :create_time        => Time.now,
                :system_mtime       => Time.now,
                :user_mtime         => Time.now,
                :lock_version       => 0)
  end

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

  private

  # archival object or resource may have an external_ark_url defined.
  # query object to see. if found, find it and return it
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

  def self.ark_name_exists?(id, type)
    case type
    when Resource
      id_field = :resource_id
    when ArchivalObject
      id_field = :archival_object_id
    else
      return false
    end

    if ArkName.first(id_field => id).nil?
      return false
    else
      return true
    end
  end
end
