require_relative 'directional_relationships'

module RelatedAgents
  extend JSONModel

  def self.included(base)
    callback = proc { |clz| RelatedAgents.set_up_date_record_handling(clz) }

    base.include(DirectionalRelationships)

    base.define_directional_relationship(:name => :related_agents,
                                         :json_property => 'related_agents',
                                         :contains_references_to_types => proc {
                                           AgentManager.registered_agents.map {|a| a[:model]}
                                         },
                                         :class_callback => callback)
  end


  # When saving/loading this relationship, link up and fetch a nested date
  # record to capture the dates.
  def self.set_up_date_record_handling(relationship_clz)
    relationship_clz.instance_eval do
      extend JSONModel
      one_to_one :relationship_date, :class => "ASDate", :key => :related_agents_rlshp_id

      include ASModel::SequelHooks

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
  end

end
