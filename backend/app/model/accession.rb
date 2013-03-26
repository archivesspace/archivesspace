class Accession < Sequel::Model(:accession)
  include ASModel
  corresponds_to JSONModel(:accession)

  include Identifiers
  include Extents
  include Subjects
  include Dates
  include ExternalDocuments
  include RightsStatements
  include Deaccessions
  include Agents
  include Relationships
  include ExternalIDs
  include CollectionManagements

  agent_relator_enum("linked_agent_archival_record_relators")

  enable_suppression
  set_model_scope :repository


  define_relationship(:name => :spawned,
                      :json_property => 'related_resources',
                      :contains_references_to_types => proc {[Resource]})



  def set_suppressed(val)
    self.suppressed = val ? 1 : 0
    obj = save

    Event.handle_suppressed(self)

    RequestContext.open(:enforce_suppression => false) do
      self.class.fire_update(self.class.to_jsonmodel(self.id), self)
    end

    val
  end


  def tree
    resources = self.linked_records(:spawned).map {|resource|
      {
        :title => resource.title,
        :id => resource.id,
        :node_type => 'resource',
        :record_uri => resource.uri,
      }
    }

    JSONModel(:accession_tree).
        from_hash(:title => self.title,
                  :id => self.id,
                  :node_type => 'accession',
                  :children => resources,
                  :record_uri => self.uri)
  end

end
