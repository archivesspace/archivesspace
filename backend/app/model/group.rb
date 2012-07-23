class Group < Sequel::Model(:groups)
  include ASModel

  many_to_many :users
end
