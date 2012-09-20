class Permission < Sequel::Model(:permissions)
  include ASModel
  plugin :validation_helpers

  def self.define(opts)
    Permission.find_or_create(opts)
  end

end
