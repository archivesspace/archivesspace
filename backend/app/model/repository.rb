class Repository < Sequel::Model(:repositories)
  include ASModel

  plugin :validation_helpers

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

    standard_groups = [{
                         :group_code => "repository-managers",
                         :description => "Managers of the #{repo_code} repository"
                       },
                       {
                         :group_code => "repository-users",
                         :description => "Users of the #{repo_code} repository"
                       }]

    standard_groups.each do |group_data|
      Group.create_from_json(JSONModel(:group).from_hash(group_data),
                             :repo_id => self.id)
    end

    Webhooks.notify("REPOSITORY_CHANGED")
  end

end
