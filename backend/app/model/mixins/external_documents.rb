module ExternalDocuments

  def self.included(base)
    base.one_to_many(:external_document)

    base.def_nested_record(:the_property => :external_documents,
                           :contains_records_of_type => :external_document,
                           :corresponding_to_association  => :external_document)
  end

end
