class NameCorporateEntity < Sequel::Model(:name_corporate_entity)
  include ASModel
  plugin :validation_helpers
end
