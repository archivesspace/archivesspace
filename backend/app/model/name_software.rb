class NameSoftware < Sequel::Model(:name_software)
  include ASModel
  plugin :validation_helpers
end
