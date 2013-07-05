module AgentNames

  def self.included(base)
    base.set_model_scope :global
    
    base.one_to_many :date, :class => "ASDate"
    
    base.def_nested_record(:the_property => :use_dates,
                           :contains_records_of_type => :date,
                           :corresponding_to_association => :date)
  end

end
