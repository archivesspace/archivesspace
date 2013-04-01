class Repository < Sequel::Model(:repository)
  include ASModel

  set_model_scope :global
  corresponds_to JSONModel(:repository)

  def validate
    super
    validates_unique(:repo_code, :message => "short name already in use")
    validates_presence(:repo_code, :message => "You must supply a short name for your repository")
    validates_presence(:name, :message => "You must give your repository a name")
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
                         :grants_permissions => ["manage_repository", "update_location_record", "update_subject_record",
                                                 "update_agent_record", "update_archival_record", "update_event_record", "view_repository",
                                                 "delete_archival_record", "suppress_archival_record"]
                       },
                       {
                         :group_code => "repository-archivists",
                         :description => "Archivists of the #{repo_code} repository",
                         :grants_permissions => ["update_location_record", "update_subject_record", "update_agent_record", "update_archival_record", "update_event_record", "view_repository"]
                       },
                       {
                         :group_code => "repository-project-managers",
                         :description => "Project managers of the #{repo_code} repository",
                         :grants_permissions => ["view_repository", "update_archival_record", "update_event_record", "update_subject_record", "update_agent_record",
                                                 "delete_archival_record", "suppress_archival_record"]
                       },
                       {
                         :group_code => "repository-advanced-data-entry",
                         :description => "Advanced Data Entry users of the #{repo_code} repository",
                         :grants_permissions => ["view_repository", "update_archival_record", "update_event_record", "update_subject_record", "update_agent_record"]
                       },
                       {
                         :group_code => "repository-basic-data-entry",
                         :description => "Basic Data Entry users of the #{repo_code} repository",
                         :grants_permissions => ["view_repository", "update_archival_record"]
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

    Notifications.notify("REPOSITORY_CHANGED")
  end

end
