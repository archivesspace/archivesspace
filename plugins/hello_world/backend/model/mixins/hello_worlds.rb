module HelloWorlds

  def self.included(base)
    base.one_to_many :who_said_hello

    base.def_nested_record(:the_property => :hello_worlds,
                           :contains_records_of_type => :hello_world,
                           :corresponding_to_association  => :who_said_hello)
  end

end
