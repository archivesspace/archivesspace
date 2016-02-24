module RevisionStatements 

  def self.included(base)
    base.one_to_many(:revision_statement)

    base.def_nested_record(:the_property => :revision_statements,
                           :contains_records_of_type => :revision_statement,
                           :corresponding_to_association  => :revision_statement)
  end

end
