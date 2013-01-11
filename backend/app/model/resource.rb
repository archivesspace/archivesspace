require_relative 'notes'

class Resource < Sequel::Model(:resource)
  include ASModel
  include Identifiers
  include Subjects
  include Extents
  include Dates
  include ExternalDocuments
  include RightsStatements
  include Instances
  include Deaccessions
  include Agents
  include Trees
  include Notes
  include Relationships
  include ExternalIDs

  tree_of(:resource, :archival_object)
  set_model_scope :repository
  corresponds_to JSONModel(:resource)

  define_relationship(:name => :spawned,
                      :json_property => 'related_accessions',
                      :contains_references_to_types => proc {[Accession]})

end
