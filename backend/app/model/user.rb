class User < Sequel::Model(:users)
  include ASModel
  plugin :validation_helpers


  def before_save
    self.username = self.username.downcase
  end

  def validate
    validates_unique(:username,
                     :message => "Username '#{self.username}' is already in use")
  end

  many_to_many :groups
end
