class Title < Sequel::Model(:title)
  include ASModel
  corresponds_to JSONModel(:title)

  set_model_scope :global

  def validate
    super
    validates_presence [:title]
  end
end
