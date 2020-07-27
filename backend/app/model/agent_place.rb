class AgentPlace < Sequel::Model(:agent_place)
  include ASModel

  corresponds_to JSONModel(:agent_place)
  
  include Notes

  set_model_scope :global

  self.one_to_many :structured_date_label, :class => "StructuredDateLabel"

  self.def_nested_record(:the_property => :dates,
                         :contains_records_of_type => :structured_date_label,
                         :corresponding_to_association => :structured_date_label)

  # ANW-429: This relationship was created in it's own table (instead of putting it in subject_rlshp) to help improve clarity since relationships can get hidden by being buried in other tables and linked by including mixins.
  self.define_relationship(:name => :subject_agent_place,
                           :json_property => 'subjects',
                           :contains_references_to_types => proc {[Subject]})

end
