require_relative 'name_corporate_entity'

class AgentCorporateEntity < Sequel::Model(:agent_corporate_entity)

  include ASModel
  corresponds_to JSONModel(:agent_corporate_entity)

  include ExternalDocuments
  include AgentManager::Mixin
  include RecordableCataloging
  include Notes
  include Publishable
  include AutoGenerator


  register_agent_type(:jsonmodel => :agent_corporate_entity,
                      :name_type => :name_corporate_entity,
                      :name_model => NameCorporateEntity)

  # This only runs when generating slugs by ID, since we have access to the authority_id in the JSON
  auto_generate :property => :slug,
                :generator => proc { |json|
                  if AppConfig[:use_human_readable_urls]
                    if json["is_slug_auto"]
                      SlugHelpers.id_based_slug_for(json, AgentCorporateEntity) if AppConfig[:auto_generate_slugs_with_id]
                    else
                      json["slug"]
                    end
                  end
                }


  def delete
    if Repository.filter(:agent_representation_id => self.id).count > 0
      raise ConflictException.new("cannot_delete_repository_agent")
    end

    check_cross_repo_delete_conflict!

    super
  end

end
