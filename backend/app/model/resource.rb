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

  tree_of(:resource, :archival_object)
  set_model_scope :repository
  corresponds_to JSONModel(:resource)

  define_relationship(:name => :spawned,
                      :json_property => 'related_accessions',
                      :contains_references_to_types => proc {[Accession]})



  def link(opts)
    child = ArchivalObject.get_or_die(opts[:child])
    child.resource_id = self.id
    child.parent_id = opts[:parent]
    child.save
  end


  def children
    ArchivalObject.filter(:resource_id => self.id, :parent_id => nil).order(:position)
  end
end
