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

  # Other associations are in mixins/agent_manager. This one is here because it only applies to people.
  self.one_to_many :agent_gender, :class => "AgentGender"

  self.def_nested_record(:the_property => :agent_genders,
                         :contains_records_of_type => :agent_gender,
                         :corresponding_to_association => :agent_gender)

  # This only runs when generating slugs by ID, since we have access to the authority_id in the JSON
  auto_generate :property => :slug,
                :generator => proc { |json|
                  if AppConfig[:use_human_readable_urls]
                    if json["is_slug_auto"]
                      SlugHelpers.id_based_slug_for(json, AgentPerson) if AppConfig[:auto_generate_slugs_with_id]
                    else
                      json["slug"]
                    end
                  end
                }

  def delete
    if User.filter(:agent_record_id => self.id).count > 0
      raise ConflictException.new("linked_to_user")
    else
      super
    end
  end

end
