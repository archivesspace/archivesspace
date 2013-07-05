class Deaccession < Sequel::Model(:deaccession)
  include ASModel
  corresponds_to JSONModel(:deaccession)

  include Extents

  set_model_scope :repository

  one_to_one :date, :class => "ASDate"
  def_nested_record(:the_property => :date,
                    :contains_records_of_type => :date,
                    :corresponding_to_association => :date,
                    :is_array => false)
end
