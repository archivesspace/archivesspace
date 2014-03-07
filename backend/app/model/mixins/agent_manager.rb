require_relative 'relationships'
require_relative 'related_agents'
require_relative 'implied_publication'
require 'set'


module AgentManager

  @@registered_agents ||= {}


  def self.register_agent_type(agent_class, opts)
    opts[:model] = agent_class
    @@registered_agents[agent_class] = opts
  end


  def self.model_for(type)
    self.registered_agents.each do |agent_type|
      return agent_type[:model] if (agent_type[:jsonmodel].to_s == type)
    end

    return nil
  end


  def self.registered_agents
    @@registered_agents.values
  end


  def self.agent_type_of(agent_class)
    @@registered_agents[agent_class]
  end


  def self.known_agent_type?(type)
    registered_agents.any? {|a| a[:jsonmodel].to_s == type}
  end


  module Mixin

    def self.included(base)
      base.extend(ClassMethods)
      base.set_model_scope :global

      base.include(Relationships)
      base.include(RelatedAgents)
      base.include(ImpliedPublication)
      base.include(Events)

      ArchivesSpaceService.loaded_hook do
        base.define_relationship(:name => :linked_agents,
                                 :contains_references_to_types => proc {
                                   base.relationship_dependencies[:linked_agents]
                                 })
      end
    end


    def update_from_json(json, opts = {}, apply_nested_records = true)
      self.class.ensure_authorized_name(json)
      self.class.ensure_display_name(json)
      self.class.combine_unauthorized_names(json)

      # Force validation to make sure we're left with a valid record after our
      # changes
      json.to_hash

      # Called for the sake of updating the JSON blob sent to the realtime indexer
      self.class.populate_display_name(json)

      super
    end


    def linked_agent_roles
      role_ids = self.class.find_relationship(:linked_agents).values_for_property(self, :role_id).uniq

      # Hackish: we only want to return roles corresponding to linked archival
      # records (not events), so we filter it at this level.
      valid_enum = BackendEnumSource.values_for("linked_agent_role")

      BackendEnumSource.values_for_ids(role_ids).values.reject {|v| !valid_enum.include?(v) }
    end


    module ClassMethods

      def populate_display_name(json)
        json.display_name = json['names'].find {|name| name['is_display_name']}
      end


      def ensure_authorized_name(json)
        if !Array(json['names']).empty? && json['names'].none? {|name| name['authorized']}
          json['names'][0]['authorized'] = true
        end
      end


      def ensure_display_name(json)
        if !Array(json['names']).empty? && json['names'].none? {|name| name['is_display_name']}
          # If no display name was specified, take the authorized one as display
          # name.
          authorized_name = json['names'].find {|name| name['authorized']}
          authorized_name['is_display_name'] = true
        end
      end


      def combine_unauthorized_names(json)
        return if Array(json['names']).empty?
        json.names = json['names'].uniq
      end


      def create_from_json(json, opts = {})
        self.ensure_authorized_name(json)
        self.ensure_display_name(json)
        self.combine_unauthorized_names(json)

        # Force validation to make sure we're left with a valid record after our
        # changes
        json.to_hash

        # Called for the sake of updating the JSON blob sent to the realtime indexer
        self.populate_display_name(json)

        super
      end


      def register_agent_type(opts)
        AgentManager.register_agent_type(self, opts)



        self.one_to_many my_agent_type[:name_type]

        self.def_nested_record(:the_property => :names,
                               :contains_records_of_type => my_agent_type[:name_type],
                               :corresponding_to_association => my_agent_type[:name_type])


        self.one_to_many :agent_contact


        self.def_nested_record(:the_property => :agent_contacts,
                               :contains_records_of_type => :agent_contact,
                               :corresponding_to_association => :agent_contact)


        self.one_to_many :date, :class => "ASDate"


        self.def_nested_record(:the_property => :dates_of_existence,
                               :contains_records_of_type => :date,
                               :corresponding_to_association => :date)

      end




      def my_agent_type
        AgentManager.agent_type_of(self)
      end


      def sequel_to_jsonmodel(obj, opts = {})
        json = super
        json.agent_type = my_agent_type[:jsonmodel].to_s
        json.linked_agent_roles = obj.linked_agent_roles

        populate_display_name(json)
        json.title = json['display_name']['sort_name']

        json
      end
    end
  end
end
