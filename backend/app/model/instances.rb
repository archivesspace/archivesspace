# Handling for models that require Instances
require_relative 'instance'

module Instances

  def self.included(base)
    base.one_to_many :instances

    base.jsonmodel_hint(:the_property => :instances,
               :contains_records_of_type => :instance,
               :corresponding_to_association => :instances,
               :always_resolve => true)
  end

end