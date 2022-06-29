class AgentGender < Sequel::Model(:agent_gender)
  include ASModel
  include Notes

  corresponds_to JSONModel(:agent_gender)

  set_model_scope :global

  self.one_to_many :structured_date_label, :class => "StructuredDateLabel"

  self.def_nested_record(:the_property => :dates,
                         :contains_records_of_type => :structured_date_label,
                         :corresponding_to_association => :structured_date_label)

end
