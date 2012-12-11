# Handling for models that require Deaccessions
require_relative 'deaccession'

module Deaccessions

  def self.included(base)
    base.one_to_many :deaccession

    base.def_nested_record(:the_property => :deaccessions,
                           :contains_records_of_type => :deaccession,
                           :corresponding_to_association  => :deaccession,
                           :always_resolve => true)
  end

end
