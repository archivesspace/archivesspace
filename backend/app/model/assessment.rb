class Assessment < Sequel::Model(:assessment)

  include ASModel
  corresponds_to JSONModel(:assessment)

  set_model_scope :repository

  include AssessmentMaterials
  include AssessmentConservationIssues

  define_relationship(:name => :assessment,
                      :json_property => 'records',
                      :contains_references_to_types => proc {[Accession, Resource, ArchivalObject, DigitalObject]})

  define_relationship(:name => :surveyed_by,
                      :json_property => 'surveyed_by',
                      :contains_references_to_types => proc {[AgentPerson]},
                      :is_array => false)
end
