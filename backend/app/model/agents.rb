require_relative 'agent_manager'
require_relative 'relationships'

module Agents

  def self.included(base)
    base.extend(ClassMethods)
    base.include(Relationships)
    base.include(ExternalIDs)

    base.define_relationship(:name => :linked_agents,
                             :json_property => 'linked_agents',
                             :contains_references_to_types => proc {AgentManager.registered_agents.map {|a| a[:model]}},
                             :class_callback => proc { |clz| base.initialize_enum(clz) })
  end


  module ClassMethods

    def agent_role_enum(enum_name)
      @agent_role_enum = enum_name
    end


    def initialize_enum(clz)
      if !@agent_role_enum
        raise "You haven't called agent_role_enum to set the list of possible values for this agent's role (#{self.inspect})"
      end

      enum = @agent_role_enum

      clz.instance_eval do
        include DynamicEnums
        uses_enums({:property => 'role', :uses_enum => enum})
      end
    end

  end




end
