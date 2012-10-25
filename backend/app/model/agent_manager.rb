module AgentManager

  @@registered_agents = {}

  def self.register_agent_type(agent_class, opts)
    @@registered_agents[agent_class] = opts
  end


  def self.registered_agents
    @@registered_agents.values
  end


  def self.agent_type_of(agent_class)
    @@registered_agents[agent_class]
  end


  module Mixin

    def self.included(base)
      base.extend(ClassMethods)
    end


    module ClassMethods

      def register_agent_type(opts)
        AgentManager.register_agent_type(self, opts)
      end


      def my_agent_type
        AgentManager.agent_type_of(self)
      end


      def sequel_to_jsonmodel(obj, type, opts = {})
        json = super
        json.agent_type = my_agent_type[:jsonmodel].to_s
        json
      end


      def agents_matching(query, max)
        self.where(name_type => my_agent_type[:name_type].
                   where(Sequel.like(Sequel.function(:lower, :sort_name),
                                     "#{query}%".downcase))).first(max)
      end
    end
  end
end
