require_relative 'auto_id_generator'

class RightsStatement < Sequel::Model(:rights_statement)
  include ASModel
  include ExternalDocuments
  include AutoIdGenerator::Mixin

  set_model_scope :repository
  corresponds_to JSONModel(:rights_statement)

  register_auto_id :identifier
end
