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
                             :class_callback => proc { |clz|
                               base.initialize_enum(clz)
                               base.initialize_terms(clz)
                             })
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


    def initialize_terms(clz)
      clz.instance_eval do
        include ASModel

        self.strict_param_setting = false

        many_to_many :term, :left_key => :linked_agents_rlshp_id, :join_table => :linked_agent_term, :order => Sequel.qualify(:linked_agent_term, :id)

        def_nested_record(:the_property => :terms,
                          :contains_records_of_type => :term,
                          :corresponding_to_association  => :term,
                          :always_resolve => true)


        def self.create(values)
          obj = super
          apply_linked_database_records(obj, {:terms => values['terms']}, true)
        end


        alias_method :delete_orig, :delete
        define_method(:delete) do
          self.remove_all_term
          delete_orig
        end


        alias_method :values_orig, :values
        define_method(:values) do
          result = values_orig

          result['terms'] = Array(self.term).map {|term| Term.to_jsonmodel(term)}

          result
        end

      end

    end

  end




end
