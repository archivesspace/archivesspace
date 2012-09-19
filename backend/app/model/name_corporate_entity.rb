require_relative 'name_mixin'

class NameCorporateEntity < Sequel::Model(:name_corporate_entity)
  include ASModel
  plugin :validation_helpers
  include NameMixin
end
