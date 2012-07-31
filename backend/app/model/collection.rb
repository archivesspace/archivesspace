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

    Collection.db[:collection_tree].
               filter(:collection_id => self.id).each do |row|
      if row[:parent_id]
        links[row[:parent_id]] ||= []
        links[row[:parent_id]] << row[:child_id]
      end
    end

    # Check for empty tree
    return { :collection_id => self.id,:title => self.title, :children => [] } if links.empty?

    # The root node is the only one appearing in the parent set but not the
    # child set.
    root_node = links.keys - links.values.flatten

    if root_node.count != 1
      raise "Couldn't fetch tree for collection #{self.id}.  Root nodes: #{root_node.inspect}"
    end

    properties = {}

    Collection.db[:archival_objects].
               filter(:id => links.keys + links.values.flatten).
               select(:id, :title).each do |row|
      properties[row[:id]] = row
    end

    {
      :collection_id => self.id,
      :title => self.title,
      :children => [assemble_tree(root_node[0], links, properties)]
    }
  end


  def update_tree(tree)
    Collection.db[:collection_tree].
               filter(:collection_id => self.id).
               delete

    nodes = tree["children"]
    while not nodes.empty?
      parent = nodes.pop

      parent["children"].each do |child|
        self.link(:parent => parent["id"],
                  :child => child["id"])

        nodes.push(child)
      end
    end
  end

end
