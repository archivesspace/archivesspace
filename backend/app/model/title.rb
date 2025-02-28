class Title < Sequel::Model(:title)
  include ASModel
  corresponds_to JSONModel(:title)

  set_model_scope :global

  def validate
    super
    validates_presence [:title]
  end

  def to_hash
    {
      "title" => self.title,
      "type" => self.type,
      "language" => self.language,
      "script" => self.script,
    }
  end
end
