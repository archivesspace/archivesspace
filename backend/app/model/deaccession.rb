class Deaccession < Sequel::Model(:deaccession)
  include ASModel
  include Extents

  set_model_scope :repository
  Sequel.extension :inflector

  one_to_one :date, :class => "ASDate"
  jsonmodel_hint(:the_property => :date,
                 :contains_records_of_type => :date,
                 :corresponding_to_association => :date,
                 :is_array => false,
                 :always_resolve => true)

  plugin :validation_helpers

end
