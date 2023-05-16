require_relative 'agent_manager'
require_relative 'relationships'

module Agents

  def self.included(base)
    base.extend(ClassMethods)
    base.include(Relationships)

    base.define_relationship(:name => :linked_agents,
                             :json_property => 'linked_agents',
                             :contains_references_to_types => proc {AgentManager.registered_agents.map {|a| a[:model]}},
                             :class_callback => proc { |clz|
                               base.initialize_enum(clz)
                               base.initialize_terms(clz)

                               type = base.my_jsonmodel.record_type
                               id_field = "#{type}_id".intern

                               clz.instance_eval do
                                 plugin :validation_helpers

                                 define_method(:validate) do
                                   if self[:is_primary]
                                     validates_unique(
                                       [:is_primary, id_field],
                                       message: "A #{type} can have only one primary linked agent")
                                   end

                                   super()
                                 end
                               end
                             })
  end


  module ClassMethods

    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super
      if self.has_primary_agents?
        jsons.each do |json|
          json['linked_agents'].each do |agent_link|
            agent_link['is_primary'] = (agent_link['is_primary'] == 1)
          end
        end
      end

      jsons
    end

    def agent_role_enum(enum_name)
      @agent_role_enum = enum_name
    end

    def agent_relator_enum(enum_name)
      @agent_relator_enum = enum_name
    end

    def initialize_enum(clz)
      role_enum = @agent_role_enum or raise "Missing agent_role_enum in #{self}"
      relator_enum = @agent_relator_enum

      if self.columns.include?(:relator_id) && relator_enum.nil?
        raise "Missing agent_relator_enum in #{self}"
      end

      clz.instance_eval do
        include DynamicEnums

        enums = []
        enums << {:property => 'role', :uses_enum => [role_enum]} if role_enum
        enums << {:property => 'relator', :uses_enum => [relator_enum]} if relator_enum

        uses_enums(*enums)
      end
    end


    def initialize_terms(clz)
      clz.instance_eval do
        include ASModel::CRUD
        include ASModel::SequelHooks

        self.strict_param_setting = false

        many_to_many :term, :left_key => :linked_agents_rlshp_id, :join_table => :linked_agent_term, :order => Sequel.qualify(:linked_agent_term, :id)

        def_nested_record(:the_property => :terms,
                          :contains_records_of_type => :term,
                          :corresponding_to_association  => :term)


        def self.create(values)
          obj = super
          obj.apply_nested_records({:terms => values['terms']}, true)
        end


        def self.handle_delete(ids_to_delete)
          self.db[:linked_agent_term].
               filter(:linked_agents_rlshp_id => ids_to_delete).
               delete

          super
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

    def has_primary_agents?
      self.my_jsonmodel.schema['properties'].dig('linked_agents', 'items', 'properties', 'is_primary') ? true : false
    end

  end
end
