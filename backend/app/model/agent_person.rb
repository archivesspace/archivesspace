require_relative 'name_person'

class AgentPerson < Sequel::Model(:agent_person)

  include ASModel
  corresponds_to JSONModel(:agent_person)

  include ExternalDocuments
  include AgentManager::Mixin
  include RecordableCataloging
  include Notes
  include Publishable
  include AutoGenerator
  include Assessments::LinkedAgent

  register_agent_type(:jsonmodel => :agent_person,
                      :name_type => :name_person,
                      :name_model => NamePerson)

  # This only runs when generating slugs by ID, since we have access to the authority_id in the JSON
  auto_generate :property => :slug,
                :generator => proc { |json| SlugHelpers.id_based_slug_for(json, AgentPerson) if AppConfig[:auto_generate_slugs_with_id]
                },
                :only_if => proc { |json| json["is_slug_auto"] && AppConfig[:use_human_readable_URLs] }


end
