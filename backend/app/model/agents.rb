require_relative 'agent_manager'
require_relative 'relationships'

module Agents

  def self.included(base)
    base.include(Relationships)

    base.define_relationship(:name => :linked_agents,
                             :json_property => 'linked_agents',
                             :contains_references_to_types => proc {AgentManager.registered_agents.map {|a| a[:model]}})
  end

end
