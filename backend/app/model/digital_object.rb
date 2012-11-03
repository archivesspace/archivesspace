#
# Lots of duplication here with resource.rb.  We'll fix that soon!
#
class DigitalObject < Sequel::Model(:digital_object)
  plugin :validation_helpers
  include ASModel
  include Subjects
  include Extents
  include Dates
  include ExternalDocuments
  include Agents

  set_model_scope :repository

  def link(opts)
    child = DigitalObjectComponent.get_or_die(opts[:child])
    child.digital_object_id = self.id
    child.parent_id = opts[:parent]
    child.save
  end


  def assemble_tree(node, links, properties)
    result = JSONModel(:digital_object_tree).new(properties[node])

    result.digital_object_component = JSONModel(:digital_object_component).uri_for(result[:id],
                                                                                   :repo_id => self.repo_id)
    if links[node]
      result.children = links[node].map do |child_id|
        assemble_tree(child_id, links, properties)
      end
    else
      result.children = []
    end

    result.to_hash
  end


  def tree
    links = {}
    properties = {}

    root_node = nil
    repository_view(DigitalObjectComponent).filter(:digital_object_id => self.id).each do |doc|
      if doc.parent_id
        links[doc.parent_id] ||= []
        links[doc.parent_id] << doc.id
      else
        root_node = doc.id
      end

      properties[doc.id] = {:title => doc.title, :id => doc.id}
    end

    # Check for empty tree
    return nil if root_node.nil?

    assemble_tree(root_node, links, properties)
  end

  def update_tree(tree)
    repository_view(:digital_object_component).
      filter(:digital_object_id => self.id).
      update(:parent_id => nil)

    # The root node has a null parent
    self.link(:parent => nil,
              :child => JSONModel(:digital_object_component).id_for(tree["digital_object_component"],
                                                                    :repo_id => self.repo_id))

    nodes = [tree]
    while not nodes.empty?
      parent = nodes.pop

      parent_id = JSONModel(:digital_object_component).id_for(parent["digital_object_component"],
                                                              :repo_id => self.repo_id)

      parent["children"].each do |child|
        child_id = JSONModel(:digital_object_component).id_for(child["digital_object_component"],
                                                               :repo_id => self.repo_id)

        self.link(:parent => parent_id, :child => child_id)
        nodes.push(child)
      end
    end
  end


  def self.create_from_json(json, opts = {})
    notes_blob = JSON(json.notes)
    json.notes = nil
    super(json, opts.merge(:notes => notes_blob))
  end


  def update_from_json(json, opts = {})
    notes_blob = JSON(json.notes)
    json.notes = nil
    super(json, opts.merge(:notes => notes_blob))
  end


  def self.sequel_to_jsonmodel(obj, type, opts = {})
    notes = JSON.parse(obj.notes || "[]")
    obj[:notes] = nil
    json = super
    json.notes = notes

    json
  end

end
