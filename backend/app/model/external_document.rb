class ExternalDocument < Sequel::Model(:external_document)
  include ASModel
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

      validates_unique([:location, "#{record}_id".intern],
                        :message => "location must be unique within a record")

      map_validation_to_json_property([:location, "#{record}_id".intern], :location)
    end

    super
  end
end
