class DigitalObject < Sequel::Model(:digital_object)
  include ASModel
  corresponds_to JSONModel(:digital_object)

  include Subjects
  include Extents
  include Dates
  include ExternalDocuments
  include Agents
  include Trees
  include Notes
  include RightsStatements
  include ExternalIDs
  include FileVersions
  include CollectionManagements
  include UserDefineds

  agent_relator_enum("linked_agent_archival_record_relators")

  tree_of(:digital_object, :digital_object_component)
  set_model_scope :repository

  define_relationship(:name => :instance_do_link,
                      :json_property => 'linked_instances',
                      :contains_references_to_types => proc {[Instance]})


  def self.sequel_to_jsonmodel(obj, opts = {})
    json = super

    json["linked_instances"] = []

    obj.linked_records(:instance_do_link).each do |link|
      json["linked_instances"].push({
          "ref" => link.resource ? link.resource.uri : link.archival_object.uri 
      })
    end

    json
  end

end
