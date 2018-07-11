require 'securerandom'

class RightsStatement < Sequel::Model(:rights_statement)
  include ASModel
  corresponds_to JSONModel(:rights_statement)

  include RightsStatementExternalDocuments
  include Notes
  include Agents
  include AutoGenerator
  include RightsStatementActs

  set_model_scope :global

  # All records that link to agents need to specify a role/relator enum
  # but be aware in this context these fields are not exposed to via the staff
  # interface.
  agent_role_enum("linked_agent_role")
  agent_relator_enum("linked_agent_archival_record_relators")

  auto_generate :property => :identifier,
                :generator => proc  { |json|
                  SecureRandom.hex
                },
                :only_on_create => true
end
