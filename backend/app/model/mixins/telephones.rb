module Telephones

  def self.included(base)
    base.one_to_many(:telephone)

    base.def_nested_record(:the_property => :telephones,
                           :contains_records_of_type => :telephone,
                           :corresponding_to_association  => :telephone)
  end

end
