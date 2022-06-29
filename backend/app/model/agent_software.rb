require_relative 'name_software'

class AgentSoftware < Sequel::Model(:agent_software)

  include ASModel
  corresponds_to JSONModel(:agent_software)

  include ExternalDocuments
  include AgentManager::Mixin
  include RecordableCataloging
  include Notes
  include Publishable
  include AutoGenerator


  register_agent_type(:jsonmodel => :agent_software,
                      :name_type => :name_software,
                      :name_model => NameSoftware)


  # This only runs when generating slugs by ID, since we have access to the authority_id in the JSON
  auto_generate :property => :slug,
                :generator => proc { |json|
                  if AppConfig[:use_human_readable_urls]
                    if json["is_slug_auto"]
                      SlugHelpers.id_based_slug_for(json, AgentSoftware) if AppConfig[:auto_generate_slugs_with_id]
                    else
                      json["slug"]
                    end
                  end
                }



  def self.system_role
    "archivesspace_agent"
  end


  def delete
    if self.system_role == self.class.system_role
      raise AccessDeniedException.new("Can't delete the system's own agent")
    end

    super
  end


  def self.archivesspace_record
    AgentSoftware[:system_role => system_role]
  end


  # Create the agent record that represents the system itself,
  # or update it if it exists but the build version has changed
  def self.ensure_correctly_versioned_archivesspace_record
    if AgentSoftware[:system_role => system_role].nil?
      json = JSONModel(:agent_software).from_hash(
                :publish => false,
                :names => [{
                  :software_name => 'ArchivesSpace',
                  :version => ASConstants.VERSION,
                  :source => 'local',
                  :rules => 'local',
                  :sort_name_auto_generate => true
              }])

      AgentSoftware.create_from_json(json,
                                     :system_generated => true,
                                     :system_role => system_role)
    else
      as_sequel = AgentSoftware[:system_role => system_role]
      if as_sequel.name_software[0].version != ASConstants.VERSION
        as_sequel.name_software[0].version = ASConstants.VERSION
        as_sequel.name_software[0].save
      end
    end
  end

end
