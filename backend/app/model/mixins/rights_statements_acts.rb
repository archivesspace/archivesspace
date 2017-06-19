module RightsStatementActs

  def self.included(base)
    base.one_to_many :rights_statement_act

    base.def_nested_record(:the_property => :acts,
                           :contains_records_of_type => :rights_statement_act,
                           :corresponding_to_association  => :rights_statement_act)
  end

end
