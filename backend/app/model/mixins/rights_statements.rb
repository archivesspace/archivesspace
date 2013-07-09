module RightsStatements

  def self.included(base)
    base.one_to_many :rights_statement

    base.def_nested_record(:the_property => :rights_statements,
                           :contains_records_of_type => :rights_statement,
                           :corresponding_to_association  => :rights_statement)
  end

end
