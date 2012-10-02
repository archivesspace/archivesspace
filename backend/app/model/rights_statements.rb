# Handling for models that require Rights Statements
require_relative 'rights_statement'

module RightsStatements

  def self.included(base)
    base.one_to_many :rights_statements

    base.jsonmodel_hint(:the_property => :rights_statements,
                        :contains_records_of_type => :rights_statement,
                        :corresponding_to_association  => :rights_statements,
                        :always_resolve => true)
  end

end
