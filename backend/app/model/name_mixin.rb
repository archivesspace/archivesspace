module NameMixin

  def validate
    is_using_source = self[:source] || self[:authority_id]

    validates_presence([:rules]) if not is_using_source
    validates_presence([:source, :authority_id]) if is_using_source
    super
  end

end
