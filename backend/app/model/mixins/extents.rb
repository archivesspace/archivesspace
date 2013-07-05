module Extents

  def self.included(base)
    base.one_to_many :extent

    base.def_nested_record(:the_property => :extents,
                           :contains_records_of_type => :extent,
                           :corresponding_to_association  => :extent)
  end

end
