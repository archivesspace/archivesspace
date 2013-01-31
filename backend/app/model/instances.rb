# Handling for models that require Instances
require_relative 'instance'

module Instances

  def self.included(base)
    base.one_to_many :instance
    Instance.many_to_one base.table_name

    base.def_nested_record(:the_property => :instances,
                           :contains_records_of_type => :instance,
                           :corresponding_to_association => :instance,
                           :always_resolve => true)
  end

end
