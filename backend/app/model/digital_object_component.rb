class DigitalObjectComponent < Sequel::Model(:digital_object_component)
  include ASModel
  corresponds_to JSONModel(:digital_object_component)

  include Subjects
  include Extents
  include Dates
  include ExternalDocuments
  include Agents
  include TreeNodes
  include Notes
  include RightsStatements
  include ExternalIDs
  include FileVersions

  agent_relator_enum("linked_agent_archival_record_relators")

  tree_record_types :digital_object, :digital_object_component

  set_model_scope :repository

  def validate
    validates_unique([:root_record_id, :component_id],
                     :message => "A Digital Object Component ID must be unique to its Digital Object")
    map_validation_to_json_property([:root_record_id, :component_id], :component_id)
    super
  end

end
