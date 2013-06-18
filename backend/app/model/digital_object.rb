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


  def validate
    validates_unique([:repo_id, :digital_object_id], :message => "Must be unique")

    map_validation_to_json_property([:repo_id, :digital_object_id], :digital_object_id)

    super
  end

end
