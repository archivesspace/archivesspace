class Repository < Sequel::Model(:repositories)
  include ASModel

  plugin :validation_helpers

  def validate
    super
    validates_unique(:repo_id, :message=>"Repository Id already in use")
  end
end
