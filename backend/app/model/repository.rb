class Repository < Sequel::Model(:repositories)
  include ASModel

  plugin :validation_helpers

  def validate
    super
    validates_unique(:repo_code, :message=>"repo_code already in use")
  end
end
