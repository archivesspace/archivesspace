# Handling for models that require Dates
require_relative 'ASDate'

module Dates

  def self.included(base)
    base.one_to_many :dates, :class => "ASDate"

    base.jsonmodel_hint(:the_property => :dates,
                        :contains_records_of_type => "ASDate",
                        :corresponding_to_association  => :dates,
                        :always_resolve => true)
  end


  def validate
    super
  end

end
