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

    def agent_relator_enum(enum_name)
      @agent_relator_enum = enum_name
    end


    def initialize_enum(clz)
      role_enum = @agent_role_enum
      relator_enum = @agent_relator_enum

      clz.instance_eval do
        include DynamicEnums

        enums = []
        enums << {:property => 'role', :uses_enum => role_enum} if role_enum
        enums << {:property => 'relator', :uses_enum => relator_enum} if relator_enum

        uses_enums(*enums)
      end
    end

  end




end
