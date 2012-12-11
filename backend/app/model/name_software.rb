require_relative 'name_mixin'

class NameSoftware < Sequel::Model(:name_software)
  include ASModel
  corresponds_to JSONModel(:name_software)
  include NameMixin
end
