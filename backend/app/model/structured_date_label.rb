class StructuredDateLabel < Sequel::Model(:structured_date_label)
  include ASModel

  corresponds_to JSONModel(:structured_date_label)

  set_model_scope :global

  one_to_one :structured_date_single, :class => "StructuredDateSingle"
  one_to_one :structured_date_range, :class => "StructuredDateRange"

  def_nested_record(:the_property => :structured_date_single,
                    :contains_records_of_type => :structured_date_single,
                    :corresponding_to_association => :structured_date_single)

  def_nested_record(:the_property => :structured_date_range,
                    :contains_records_of_type => :structured_date_range,
                    :corresponding_to_association => :structured_date_range)



end

