class Agent < Sequel::Model(:agents)
  include ASModel

  plugin :validation_helpers

end
