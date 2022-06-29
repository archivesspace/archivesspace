require 'factory_bot'
require 'spec/lib/factory_bot_helpers'

# See common/spec/lib/factory_bot_helpers for shared JSONModel factories

FactoryBot.define do

  def JSONModel(key)
    JSONModel::JSONModel(key)
  end

  to_create {|instance| instance.save}

end
