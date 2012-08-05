class Collection < Sequel::Model(:collections)
  plugin :validation_helpers
  include ASModel

  def link(opts)
    now = Time.now
    Collection.db[:collection_tree].
               insert(:parent_id => opts[:parent],
                      :child_id => opts[:child],
                      :collection_id => self.id,
                      :create_time => now,
                      :last_modified => now)
  end


  def assemble_tree(node, links, properties)
    result = properties[node]

    result[:archival_object] = JSONModel(:archival_object).uri_for(result[:id],
                                                                   :repo_id => self.repo_id)
    result.delete(:id)

    if links[node]
      result[:children] = links[node].map do |child_id|
        assemble_tree(child_id, links, properties)
      end
    else
      result[:children] = []
    end

    result
  end


  def tree
    links = {}

    root_node = nil
    Collection.db[:collection_tree].
               filter(:collection_id => self.id).each do |row|
      if row[:parent_id]
        links[row[:parent_id]] ||= []
        links[row[:parent_id]] << row[:child_id]
      else
        root_node = row[:child_id]
      end
    end

    # Check for empty tree
    return [] if root_node.nil?

    properties = {}

    Collection.db[:archival_objects].
               filter(:id => ([root_node] + links.keys + links.values.flatten)).
               select(:id, :title).each do |row|
      properties[row[:id]] = row
    end

    assemble_tree(root_node, links, properties)
  end


  def update_tree(tree)
    Collection.db[:collection_tree].
               filter(:collection_id => self.id).
               delete

    # The root node has a null parent
    self.link(:parent => nil,
              :child => JSONModel("archival_object").id_for(tree["archival_object"],
                                                            :repo_id => self.repo_id))

    nodes = [tree]
    while not nodes.empty?
      parent = nodes.pop

      parent_id = JSONModel("archival_object").id_for(parent["archival_object"],
                                                      :repo_id => self.repo_id)

      parent["children"].each do |child|
        child_id = JSONModel("archival_object").id_for(child["archival_object"],
                                                       :repo_id => self.repo_id)

        self.link(:parent => parent_id, :child => child_id)
        nodes.push(child)
      end
    end
  end

end
