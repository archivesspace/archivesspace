module NameMixin

  def self.included(base)
    base.set_model_scope :global
  end

end
