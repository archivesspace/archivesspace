class User < Sequel::Model(:users)
  include ASModel

  def before_save
    self.username = self.username.downcase
  end

  many_to_many :groups
end
