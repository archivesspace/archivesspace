module NameMixin

  def validate
    is_using_source = self[:source]
    is_using_authority_id = self[:authority_id]

    validates_presence([:rules]) if not is_using_source
    validates_presence([:source]) if is_using_authority_id
    super
  end


  def self.included(base)
    base.set_model_scope :global
  end

end
