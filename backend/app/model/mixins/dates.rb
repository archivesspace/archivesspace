module Dates

  def self.included(base)
    base.one_to_many :date, :class => "ASDate"

    base.def_nested_record(:the_property => :dates,
                           :contains_records_of_type => :date,
                           :corresponding_to_association  => :date)
  end

end
