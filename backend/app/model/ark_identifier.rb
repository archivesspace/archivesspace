class ARKIdentifier < Sequel::Model(:ark_identifier)
  include ASModel

  one_to_one :resource  
  one_to_one :accession
  one_to_one :digital_object

  # validations:
  # must be linked to a resource, accession or digital object
  # cannot link to more than one type of resource
  # can't have more than one ark_id point to the same resource, accession and digital_object

  def validate
    validate_resources_defined
    validates_unique(:resource_id, :message => "ARK must point to a unique Resource")
    validates_unique(:accession_id, :message => "ARK must point to a unique Accession")
    validates_unique(:digital_object_id, :message => "ARK must point to a unique Digital Object")
    super
  end

  def validate_resources_defined
    resources_defined = 0
    resources_defined += 1 unless self.resource_id.nil?
    resources_defined += 1 unless self.accession_id.nil?
    resources_defined += 1 unless self.digital_object_id.nil?

    unless resources_defined == 1
      errors.add(:base, 'Exactly one of [resource_id, digital_object_id, accession_id] must be defined.') 
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

  def self.create_from_accession(accession)
    self.insert(:accession_id     => accession.id,
                :created_by       => 'admin',
                :last_modified_by => 'admin',
                :create_time      => Time.now,
                :system_mtime     => Time.now,
                :user_mtime       => Time.now,
                :lock_version     => 0)
  end

  def self.create_from_digital_object(digital_object)
    self.insert(:digital_object_id => digital_object.id,
                :created_by        => 'admin',
                :last_modified_by  => 'admin',
                :create_time       => Time.now,
                :system_mtime      => Time.now,
                :user_mtime        => Time.now,
                :lock_version      => 0)
  end
  
  def self.get_ark_url(id, type)
    case type
    when :digital_object
      id_field = :digital_object_id
      klass_sym = :digital_object
    when :resource
      id_field = :resource_id
      klass_sym = :resource
    when :accession
      id_field = :accession_id
      klass_sym = :accession
    else
      return nil
    end

    ark = ARKIdentifier.first(id_field => id)

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

    #ark = ARKIdentifier.first(:resource_id => id)
    #return "#{AppConfig[:ark_url_prefix]}/ark:/#{AppConfig[:ark_naan]}/#{ark.id}" if ark
#
    #ark = ARKIdentifier.first(:accession_id => id)
    #return "#{AppConfig[:ark_url_prefix]}/ark:/#{AppConfig[:ark_naan]}/#{ark.id}" if ark
    #return ""
  end

  private

  # digital object, accession or resource may have an external_ark_url defined.
  # query object to see. if found, find it and return it
  def self.get_external_ark_url(id, type)
    case type
    when :digital_object
      klass = DigitalObject
    when :accession
      klass = Accession
    when :resource
      klass = Resource
    else
      return nil
    end

    entity = klass.where(:id => id).first
    return entity.send(:external_ark_url)
  end
end