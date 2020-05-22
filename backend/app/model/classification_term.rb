require 'digest/sha1'

class ClassificationTerm < Sequel::Model(:classification_term)
  include ASModel
  include TreeNodes
  include ClassificationIndexing
  include Publishable
  include AutoGenerator

  enable_suppression

  corresponds_to JSONModel(:classification_term)
  set_model_scope(:repository)

  tree_record_types :classification, :classification_term

  define_relationship(:name => :classification_term_creator,
                      :json_property => 'creator',
                      :contains_references_to_types => proc {
                        AgentManager.registered_agents.map {|a| a[:model]}
                      },
                      :is_array => false)

  define_relationship(:name => :classification,
                      :json_property => 'linked_records',
                      :contains_references_to_types => proc {[Accession, Resource]})

  auto_generate :property => :display_string,
                :generator => proc { |json|
                  json['title']
                }


  auto_generate :property => :slug,
                :generator => proc { |json|
                  if AppConfig[:use_human_readable_urls]
                    if json["is_slug_auto"]
                      AppConfig[:auto_generate_slugs_with_id] ? 
                        SlugHelpers.id_based_slug_for(json, ClassificationTerm) : 
                        SlugHelpers.name_based_slug_for(json, ClassificationTerm)
                    else
                      json["slug"]
                    end
                  end
                }


  def self.create_from_json(json, opts = {})
    self.set_path_from_root(json)
    obj = super(json, :title_sha1 => Digest::SHA1.hexdigest(json.title))
    obj.reindex_children
    obj
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    self.class.set_path_from_root(json)
    obj = super(json, {:title_sha1 => Digest::SHA1.hexdigest(json.title)}, apply_nested_records)
    obj.reindex_children
    obj
  end


  def self.set_path_from_root(json)
    path = [{'title' => json.title, 'identifier' => json.identifier}]
    parent_id = json.parent ? self.parse_reference(json.parent['ref'], {})[:id] : nil

    while parent_id
      node = ClassificationTerm[parent_id]
      path << {'title' => node.title, 'identifier' => node.identifier}
      parent_id = node.parent_id
    end

    root = Classification[self.parse_reference(json.classification['ref'], {})[:id]]
    path << {'title' => root.title, 'identifier' => root.identifier}

    json['path_from_root'] = path.reverse
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.each do |json|
      self.set_path_from_root(json)
    end

    jsons
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
