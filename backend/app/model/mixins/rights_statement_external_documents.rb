module RightsStatementExternalDocuments

  def self.included(base)
    base.one_to_many(:external_document, :class => "RightsStatementExternalDocument")

    base.def_nested_record(:the_property => :external_documents,
                           :contains_records_of_type => :rights_statement_external_document,
                           :corresponding_to_association  => :external_document)
  end

end
