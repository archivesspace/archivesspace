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
  include Instances
  include UserDefineds
  include Classifications
  include AutoGenerator
  include Transferable

  agent_relator_enum("linked_agent_archival_record_relators")

  enable_suppression
  set_model_scope :repository


  define_relationship(:name => :spawned,
                      :json_property => 'related_resources',
                      :contains_references_to_types => proc {[Resource]})


  auto_generate :property => :label,
                :generator => proc { |json|

                  label = ""

                  %w(title id_0 id_1 id_2 id_3).each do |p|

                    if json[p]
                      label += ", " if !label.empty?
                      label += json[p]
                    end
                  end

                  label
                }


  def set_suppressed(val)
    self.suppressed = val ? 1 : 0
    obj = save

    Event.handle_suppressed(self)

    RequestContext.open(:enforce_suppression => false) do
      self.class.fire_update(self.class.to_jsonmodel(self.id), self)
    end

    val
  end

end
