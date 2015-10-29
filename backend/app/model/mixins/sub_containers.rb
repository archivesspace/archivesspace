module SubContainers

  def self.included(base)
    base.one_to_many :sub_container

    base.def_nested_record(:the_property => :sub_container,
                      :is_array => false,
                      :contains_records_of_type => :sub_container,
                      :corresponding_to_association => :sub_container)
  end

end
