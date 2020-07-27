class AgentFunction < Sequel::Model(:agent_function)
  include ASModel

  corresponds_to JSONModel(:agent_function)
  
  include Notes

  set_model_scope :global

  self.one_to_many :structured_date_label, :class => "StructuredDateLabel"

  self.def_nested_record(:the_property => :dates,
                         :contains_records_of_type => :structured_date_label,
                         :corresponding_to_association => :structured_date_label)

  self.define_relationship(:name => :subject_agent_function,
                           :json_property => 'subjects',
                           :contains_references_to_types => proc {[Subject]})

  self.define_relationship(:name => :subject_agent_function_place,
                           :json_property => 'places',
                           :contains_references_to_types => proc {[Subject]})
end
