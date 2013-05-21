require 'digest/sha1'
require_relative 'classification_indexing'

class ClassificationTerm < Sequel::Model(:classification_term)
  include ASModel
  include Relationships
  include Orderable
  include ClassificationIndexing

  corresponds_to JSONModel(:classification_term)
  set_model_scope(:repository)

  orderable_root_record_type :classification, :classification_term

  define_relationship(:name => :classification_term_creator,
                      :json_property => 'creator',
                      :contains_references_to_types => proc {
                        AgentManager.registered_agents.map {|a| a[:model]}
                      },
                      :is_array => false)


  def self.create_from_json(json, opts = {})
    super(json, :title_sha1 => Digest::SHA1.hexdigest(json.title))
  end


  def update_from_json(json, opts = {}, apply_linked_records = true)
    super(json, {:title_sha1 => Digest::SHA1.hexdigest(json.title)}, apply_linked_records)
  end


  def self.sequel_to_jsonmodel(obj, opts = {})
    json = super

    path = []
    node = obj
    while node
      path << {'title' => node.title, 'identifier' => node.identifier}
      node = self[node.parent_id]
    end

    root = Classification[obj.root_record_id]
    path << {'title' => root.title, 'identifier' => root.identifier}

    json['path_from_root'] = path.reverse

    json
  end


  def validate
    validates_unique([:parent_name, :title_sha1],
                     :message => "must be unique to its level in the tree")

    validates_unique([:parent_name, :identifier],
                     :message => "must be unique to its level in the tree")

    map_validation_to_json_property([:parent_name, :title_sha1], :title)
    map_validation_to_json_property([:parent_name, :identifier], :identifier)

    super
  end

end
