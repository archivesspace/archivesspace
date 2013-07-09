module CollectionManagements

  def self.included(base)
    base.one_to_one :collection_management

    base.def_nested_record(:the_property => :collection_management,
                           :contains_records_of_type => :collection_management,
                           :corresponding_to_association  => :collection_management,
                           :is_array => false)
  end

end
