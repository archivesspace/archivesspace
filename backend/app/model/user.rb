class User < Sequel::Model(:users)
  include ASModel

  many_to_many :groups
end
