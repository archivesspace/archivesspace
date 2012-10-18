# Handling for models that require Deaccessions
require_relative 'deaccession'

module Deaccessions

  def self.included(base)
    base.one_to_many :deaccessions

    base.jsonmodel_hint(:the_property => :deaccessions,
                        :contains_records_of_type => :deaccession,
                        :corresponding_to_association  => :deaccessions,
                        :always_resolve => true)
  end

end
