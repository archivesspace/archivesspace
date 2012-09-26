class ExternalDocument < Sequel::Model(:external_documents)
  include ASModel

  plugin :validation_helpers

  many_to_one :accession
  many_to_one :resource
  many_to_one :archival_object
  many_to_one :agent_person
  many_to_one :agent_family
  many_to_one :agent_corporate_entity
  many_to_one :agent_software
  many_to_one :subject

end
