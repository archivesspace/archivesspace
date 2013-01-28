class Repository < Sequel::Model(:repository)
  include ASModel

  set_model_scope :global
  corresponds_to JSONModel(:repository)


  def validate
    super
    validates_unique(:repo_code, :message => "repo_code already in use")
    validates_presence(:repo_code, :message => "You must supply a repository code")
    validates_presence(:description, :message => "You must give your repository a description")
  end


  def self.exists?(id)
    not Repository[id].nil?
  end

  def after_create

    if self.repo_code == Group.GLOBAL
      # No need for standard groups on this one.
      return
    end

    standard_groups = [{
                         :group_code => "repository-managers",
                         :description => "Managers of the #{repo_code} repository",
                         :grants_permissions => ["manage_repository", "update_location_record", "update_subject_record", "update_agent_record", "update_archival_record", "view_repository"]
                       },
                       {
                         :group_code => "repository-archivists",
                         :description => "Archivists of the #{repo_code} repository",
                         :grants_permissions => ["update_location_record", "update_subject_record", "update_agent_record", "update_archival_record", "view_repository"]
                       },
                       {
                         :group_code => "repository-project-managers",
                         :description => "Project managers of the #{repo_code} repository",
                         :grants_permissions => ["view_repository", "update_archival_record", "update_subject_record", "update_agent_record"]
                       },
                       {
                         :group_code => "repository-viewers",
                         :description => "Viewers of the #{repo_code} repository",
                         :grants_permissions => ["view_repository"]
                       }]

    RequestContext.open(:repo_id => self.id) do
      standard_groups.each do |group_data|
        Group.create_from_json(JSONModel(:group).from_hash(group_data),
                               :repo_id => self.id)
      end
    end

    Webhooks.notify("REPOSITORY_CHANGED")
  end

end
