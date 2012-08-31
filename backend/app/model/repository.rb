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

end
