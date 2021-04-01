module ParallelAgentNames

  def self.included(base)
    base.set_model_scope :global

    base.one_to_many :structured_date_label, :class => "StructuredDateLabel"

    base.def_nested_record(:the_property => :use_dates,
                           :contains_records_of_type => :structured_date_label,
                           :corresponding_to_association => :structured_date_label)
  end
end
