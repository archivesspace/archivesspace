module NameMixin

  def self.included(base)
    base.set_model_scope :global

    base.include DynamicEnums
    base.uses_enums({:property => 'source', :uses_enum => 'name_source'},
                    {:property => 'rules', :uses_enum => 'name_rule'})
  end

end
