# Handling for models that require External Documents
require_relative 'external_document'

module ExternalDocuments

  def self.included(base)
    base.one_to_many :external_documents

    base.jsonmodel_hint(:the_property => :external_documents,
                        :contains_records_of_type => :external_document,
                        :corresponding_to_association  => :external_documents,
                        :always_resolve => true)
  end

end
