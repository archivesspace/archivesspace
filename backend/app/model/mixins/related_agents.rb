module RelatedAgents
  extend JSONModel

  def self.included(base)
    callback = proc { |clz|

      clz.instance_eval do
        extend JSONModel
        one_to_one :relationship_date, :class => "ASDate", :key => :related_agents_rlshp_id

        def self.create(values)
          date_values = values.delete('dates')
          obj = super

          if date_values
            date = ASDate.create_from_json(JSONModel(:date).from_hash(date_values))
            obj.relationship_date = date
            obj.save
          end

          obj
        end


        alias_method :delete_orig, :delete
        define_method(:delete) do
          relationship_date.delete if relationship_date
          delete_orig
        end


        alias_method :values_orig, :values
        define_method(:values) do
          result = values_orig

          if self.relationship_date
            result['dates'] = ASDate.to_jsonmodel(self.relationship_date).to_hash
          end

          result
        end
      end

    }


    base.define_relationship(:name => :related_agents,
                             :json_property => 'related_agents',
                             :contains_references_to_types => proc {
                               AgentManager.registered_agents.map {|a| a[:model]}
                             },
                             :class_callback => callback)

    base.extend(ClassMethods)
  end


  def self.prepare_related_agents_for_storage(json)
    Array(json['related_agents']).each do |relationship|
      # Relationships are directionless by default, but related agent
      # relationships actually have a direction (e.g. A is a child of B)
      #
      # We store the URI that is the subject of this relationship as a separate
      # property to preserve this direction.
      #
      relationship['relationship_target'] = relationship['ref']
    end
  end


  def self.prepare_related_agents_for_display(json)
    Array(json['related_agents']).each do |relationship|
      if relationship['relationship_target'] == json.uri
        # This means we're looking at the relationship from the other side.
        #
        # For example, if the relationship is "A is a parent of B", then we
        # want:
        #
        #   * 'GET A' to yield  {relator => 'is_parent_of', ref => 'B'}
        #   * 'GET B' to yield  {relator => 'is_child_of', ref => 'A'}
        #
        # So we want to invert the relator for this case.

        relator_values = JSONModel.enum_values(JSONModel(relationship['jsonmodel_type'].intern).schema['properties']['relator']['dynamic_enum'])
        relator_values -= ['other_unmapped'] # grumble.

        if relator_values.length == 2
          # When there are two possible values we assume they're inverses
          # Set the relator to whatever the inverse of the current one is.
          relationship['relator'] = (relator_values - [relationship['relator']]).first
        end
      end
    end
  end


  def update_from_json(json, opts = {}, apply_linked_records = true)
    RelatedAgents.prepare_related_agents_for_storage(json)
    super
  end


  module ClassMethods

    def create_from_json(json, opts = {})
      RelatedAgents.prepare_related_agents_for_storage(json)
      super
    end


    def sequel_to_jsonmodel(obj, opts = {})
      json = super
      RelatedAgents.prepare_related_agents_for_display(json)
      json
    end
  end



end
