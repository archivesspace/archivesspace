require_relative 'name_mixin'

class NameSoftware < Sequel::Model(:name_software)
  include ASModel
  plugin :validation_helpers
  include NameMixin
end
