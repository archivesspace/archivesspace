require 'digest/sha1'

class ExternalDocument < Sequel::Model(:external_document)
  include ASModel
  include Publishable
  corresponds_to JSONModel(:external_document)

  set_model_scope :global

  def validate
    [:accession, :archival_object,
     :resource, :subject,
     :agent_person,
     :agent_family,
     :agent_corporate_entity,
     :agent_software,
     :rights_statement,
     :digital_object,
     :digital_object_component].each do |record|

      validates_unique([:location_sha1, "#{record}_id".intern],
                        :message => "location and title must have unique values within a record")

      map_validation_to_json_property([:location_sha1, "#{record}_id".intern], :location)
    end

    super
  end

  def self.generate_location_sha1(json)
    Digest::SHA1.hexdigest(json.location + json.title )
  end

  def self.create_from_json(json, opts = {})
    super(json, opts.merge(:location_sha1 => generate_location_sha1(json)))
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    self[:location_sha1] = self.class.generate_location_sha1(json)
    super
  end

end
