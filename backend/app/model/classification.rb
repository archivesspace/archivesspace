require_relative 'classification_indexing'

class Classification < Sequel::Model(:classification)
  include ASModel
  include Relationships
  include Trees
  include ClassificationIndexing

  corresponds_to JSONModel(:classification)
  set_model_scope(:repository)

  tree_of(:classification, :classification_term)

  define_relationship(:name => :classification_creator,
                      :json_property => 'creator',
                      :contains_references_to_types => proc {
                        AgentManager.registered_agents.map {|a| a[:model]}
                      },
                      :is_array => false)


  def self.sequel_to_jsonmodel(obj, opts = {})
    json = super
    json['path_from_root'] = [{'title' => obj.title, 'identifier' => obj.identifier}]
    json
  end

end
