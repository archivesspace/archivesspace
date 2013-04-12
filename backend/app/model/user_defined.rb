class UserDefined < Sequel::Model(:user_defined)
  include ASModel

  set_model_scope :repository
  corresponds_to JSONModel(:user_defined)

end
