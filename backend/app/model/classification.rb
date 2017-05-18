class Classification < Sequel::Model(:classification)
  include ASModel
  include Trees
  include ClassificationIndexing
  include Publishable

  enable_suppression

  corresponds_to JSONModel(:classification)
  set_model_scope(:repository)

  tree_of(:classification, :classification_term)

  define_relationship(:name => :classification_creator,
                      :json_property => 'creator',
                      :contains_references_to_types => proc {
                        AgentManager.registered_agents.map {|a| a[:model]}
                      },
                      :is_array => false)

  define_relationship(:name => :classification,
                      :json_property => 'linked_records',
                      :contains_references_to_types => proc {[Accession, Resource]})
  

  def self.set_path_from_root(json)
    json['path_from_root'] = [{'title' => json.title, 'identifier' => json.identifier}]
  end


  def self.create_from_json(json, opts = {})
    self.set_path_from_root(json)
    obj = super
    obj.reindex_children
    obj
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    self.class.set_path_from_root(json)
    obj = super
    obj.reindex_children
    obj
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      self.set_path_from_root(json)
      json['has_classification_terms'] = obj.children?
    end

    jsons
  end


  def load_node_properties(node, properties, ids_of_interest = :all)
    super
    properties[node.id][:identifier] = node.identifier
  end


  def load_root_properties(properties, ids_of_interest = :all)
    super
    properties[:identifier] = self.identifier
  end

end
