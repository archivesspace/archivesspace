module UserDefineds

  def self.included(base)
    base.one_to_one :user_defined

    base.def_nested_record(:the_property => :user_defined,
                           :contains_records_of_type => :user_defined,
                           :corresponding_to_association  => :user_defined,
                           :is_array => false)
  end

end
