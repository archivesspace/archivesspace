require_relative 'name_software'

class AgentSoftware < Sequel::Model(:agent_software)

  include ASModel
  corresponds_to JSONModel(:agent_software)

  include ExternalDocuments
  include AgentManager::Mixin
  include RecordableCataloging
  include Notes


  register_agent_type(:jsonmodel => :agent_software,
                      :name_type => :name_software,
                      :name_model => NameSoftware)


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


  # Create the agent record that represents the system itself
  def self.create_archivesspace_record
    if AgentSoftware[:system_role => system_role].nil?
      json = JSONModel(:agent_software).from_hash(
                :publish => false,
                :names => [{
                  :software_name => 'ArchivesSpace',
                  :version => 'alpha',
                  :source => 'local',
                  :rules => 'local',
                  :sort_name_auto_generate => true
              }])

      AgentSoftware.create_from_json(json,
                                     :system_generated => true,
                                     :system_role => system_role)
    end
  end


end
