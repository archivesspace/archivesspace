class ARKName < Sequel::Model(:ark_name)
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
    self.insert(:resource_id      => resource.id,
                :created_by       => 'admin',
                :last_modified_by => 'admin',
                :create_time      => Time.now,
                :system_mtime     => Time.now,
                :user_mtime       => Time.now,
                :lock_version     => 0)
  end

  def self.create_from_archival_object(archival_object)
    self.insert(:archival_object_id => archival_object.id,
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

    ark = ARKName.first(id_field => id)

    if ark
      external_url = get_external_ark_url(ark.send(id_field), klass_sym)

      if external_url
        return external_url
      else
        return "#{AppConfig[:ark_url_prefix]}/ark:/#{AppConfig[:ark_naan]}/#{ark.id}"
      end
    else
      return nil
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

    # this should be a call to #where, but the scoping restrictions in ASmodel_crud gets us in trouble here.
    # Since we are loading records given an ARK Name, we don't know the repo
    # our entity resides in and can't provide the right scoping.
    # So, for now, we get around this by using raw SQL.
    entity = klass.fetch("SELECT external_ark_url from #{table} WHERE id = #{id.to_i}").first
    return entity.send(:external_ark_url)
  end
end
