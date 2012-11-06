class Resource < Sequel::Model(:resource)
  plugin :validation_helpers
  include ASModel
  include Identifiers
  include Subjects
  include Extents
  include Dates
  include ExternalDocuments
  include RightsStatements
  include Instances
  include Deaccessions
  include Agents

  set_model_scope :repository


  def link(opts)
    child = ArchivalObject.get_or_die(opts[:child])
    child.resource_id = self.id
    child.parent_id = opts[:parent]
    child.save
  end


  def assemble_tree(node, links, properties)
    result = properties[node].clone

    result['archival_object'] = self.class.uri_for(:archival_object, result[:id])
    if links[node]
      result['children'] = links[node].map do |child_id|
        assemble_tree(child_id, links, properties)
      end
    else
      result['children'] = []
    end

    result
  end


  def children
    ArchivalObject.filter(:resource_id => self.id, :parent_id => nil)
  end


  def tree
    links = {}
    properties = {}

    root_node = nil
    ArchivalObject.this_repo.filter(:resource_id => self.id).each do |ao|
      if ao.parent_id
        links[ao.parent_id] ||= []
        links[ao.parent_id] << ao.id
      else
        root_node = ao.id
      end

      properties[ao.id] = {:title => ao.title, :id => ao.id, :jsonmodel_type => :archival_object}
    end

    # Check for empty tree
    return {} if root_node.nil?

    assemble_tree(root_node, links, properties)
  end


  def update_tree(tree)
    ArchivalObject.this_repo.
      filter(:resource_id => self.id).
      update(:parent_id => nil)

    # The root node has a null parent
    self.link(:parent => nil,
              :child => JSONModel(:archival_object).id_for(tree["archival_object"],
                                                           :repo_id => self.repo_id))

    nodes = [tree]
    while not nodes.empty?
      parent = nodes.pop

      parent_id = JSONModel(:archival_object).id_for(parent["archival_object"],
                                                     :repo_id => self.repo_id)

      parent["children"].each do |child|
        child_id = JSONModel(:archival_object).id_for(child["archival_object"],
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


  def self.records_matching(query, max)
    self.this_repo.where(Sequel.like(Sequel.function(:lower, :title),
                                     "#{query}%".downcase)).first(max)
  end


end
