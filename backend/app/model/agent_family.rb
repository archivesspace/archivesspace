require_relative 'name_family'

class AgentFamily < Sequel::Model(:agent_family)

  include ASModel
  corresponds_to JSONModel(:agent_family)

  include ExternalDocuments
  include AgentManager::Mixin
  include RecordableCataloging
  include Notes
  include Publishable
  include AutoGenerator


  register_agent_type(:jsonmodel => :agent_family,
                      :name_type => :name_family,
                      :name_model => NameFamily)



  # This only runs when generating slugs by ID, since we have access to the authority_id in the JSON
  auto_generate :property => :slug,
                :generator => proc { |json|
                  if AppConfig[:use_human_readable_urls]
                    if json["is_slug_auto"]
                      SlugHelpers.id_based_slug_for(json, AgentFamily) if AppConfig[:auto_generate_slugs_with_id]
                    else
                      json["slug"]
                    end
                  end
                }


end
