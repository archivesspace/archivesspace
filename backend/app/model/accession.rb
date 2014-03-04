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
  include Events
  include Publishable

  agent_role_enum("linked_agent_role")
  agent_relator_enum("linked_agent_archival_record_relators")

  enable_suppression
  set_model_scope :repository


  define_relationship(:name => :spawned,
                      :json_property => 'related_resources',
                      :contains_references_to_types => proc {[Resource]})


  auto_generate :property => :display_string,
                :generator => proc { |json|

                  display_string = ""

                  %w(title id_0 id_1 id_2 id_3).each do |p|

                    if json[p]
                      display_string += ", " if !display_string.empty?
                      display_string += json[p]
                    end
                  end

                  display_string
                }
end
