class AgentPlace < Sequel::Model(:agent_place)
  include ASModel

  corresponds_to JSONModel(:agent_place)

  include Notes
  include TouchRecords

  set_model_scope :global

  self.one_to_many :structured_date_label, :class => "StructuredDateLabel"

  self.def_nested_record(:the_property => :dates,
                         :contains_records_of_type => :structured_date_label,
                         :corresponding_to_association => :structured_date_label)


  self.define_relationship(:name => :subject_agent_subrecord,
                           :json_property => 'subjects',
                           :contains_references_to_types => proc {[Subject]})

  def self.touch_records(obj)
    [{
      type: Subject, ids: (
        AgentManager.linked_subjects(obj.id, :subject_agent_subrecord, :agent_place)
      ).uniq
    }]
  end
end
