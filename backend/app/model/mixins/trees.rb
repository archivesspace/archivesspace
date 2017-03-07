module Trees

  NODE_PAGE_SIZE = 2000

  def self.included(base)
    base.extend(ClassMethods)
  end


  def adopt_children(old_parent)
    self.class.node_model.this_repo
      .filter(:root_record_id => old_parent.id,
              :parent_id => nil)
      .order(:position).each do |root_child|
      root_child.set_root(self)
    end
  end


  def assimilate(victims)
    victims.each do |victim|
      adopt_children(victim)
    end

    Event.for_archival_record_merge(self, victims)

    super
  end


  def children
    self.class.node_model.
           this_repo.filter(:root_record_id => self.id,
                            :parent_id => nil)
  end


  def build_node_query
    self.class.node_model.this_repo.filter(:root_record_id => self.id)
  end


  def load_node_properties(node, properties, ids_of_interest = :all)
    # Does nothing by default, but classes that use this mixin add their own
    # behaviour here.
  end


  def load_root_properties(properties, ids_of_interest = :all)
    # Does nothing by default, but classes that use this mixin add their own
    # behaviour here.
  end


  # A tree that only contains nodes that are needed for displaying 'node'
  #
  # That is: any ancestors of 'node', plus the direct children of any ancestor
  def partial_tree(node_of_interest)
    ids_of_interest = []
    nodes_to_check = [node_of_interest]

    while !nodes_to_check.empty?
      node = nodes_to_check.pop

      # Include the node itself
      ids_of_interest << node.id if node != :root

      # Plus any of its siblings in this tree
      self.class.node_model.
           filter(:parent_id => (node == :root) ? nil : node.parent_id,
                  :root_record_id => self.id).
           select(:id).all.each do |row|
        ids_of_interest << row[:id]
      end

      if node != :root && node.parent_id
        parent = self.class.node_model[node.parent_id]
        nodes_to_check << parent
      end
    end


    # Include the children of the node of interest too
    if node_of_interest != :root
      self.class.node_model.
           filter(:parent_id => node_of_interest.id,
                  :root_record_id => self.id).
           select(:id).all.each do |row|
        ids_of_interest << row[:id]
      end
    end


    tree(ids_of_interest)
  end


  def tree(ids_of_interest = :all)
    links = {}
    properties = {}

    root_type = self.class.root_type
    node_type = self.class.node_type

    top_nodes = []

    query = build_node_query

    has_children = {}
    if ids_of_interest != :all
      # Further limit our query to only the nodes we want to hear about
      query = query.filter(:id => ids_of_interest)

      # And check whether those nodes have children as cheaply as possible
      self.class.node_model.filter(:parent_id => ids_of_interest).distinct.select(:parent_id).all.each do |row|
        has_children[row[:parent_id]] = true
      end
    end

    offset = 0
    while true
      nodes = query.limit(NODE_PAGE_SIZE, offset).all

      nodes.each do |node|
        if node.parent_id
          links[node.parent_id] ||= []
          links[node.parent_id] << [node.position, node.id]
        else
          top_nodes << [node.position, node.id]
        end

        properties[node.id] = {
          :title => node[:title],
          :id => node.id,
          :record_uri => self.class.uri_for(node_type, node.id),
          :publish => node.respond_to?(:publish) ? node.publish===1 : true,
          :suppressed => node.respond_to?(:suppressed) ? node.suppressed===1 : false,
          :node_type => node_type.to_s
        }

        if ids_of_interest != :all
          properties[node.id]['has_children'] = !!has_children[node.id]
        end

        load_node_properties(node, properties, ids_of_interest)
      end

      if nodes.empty?
        break
      else
        offset += NODE_PAGE_SIZE
      end
    end


    result = {
      :title => self.title,
      :id => self.id,
      :node_type => root_type.to_s,
      :publish => self.respond_to?(:publish) ? self.publish===1 : true,
      :suppressed => self.respond_to?(:suppressed) ? self.suppressed===1 : false,
      :children => top_nodes.sort_by(&:first).map {|position, node| self.class.assemble_tree(node, links, properties)},
      :record_uri => self.class.uri_for(root_type, self.id)
    }
    
    if  self.respond_to?(:finding_aid_filing_title) && !self.finding_aid_filing_title.nil? && self.finding_aid_filing_title.length > 0
      result[:finding_aid_filing_title] = self.finding_aid_filing_title
    end

    load_root_properties(result, ids_of_interest)

    JSONModel("#{self.class.root_type}_tree".intern).from_hash(result, true, true)
  end

  # Return a depth-first-ordered list of URIs under this tree (starting with the tree itself)
  def ordered_records
    id_positions = {}
    parent_to_child_id = {}

    self.class.node_model
      .filter(:root_record_id => self.id)
      .select(:id, :position, :parent_id).each do |row|

      id_positions[row[:id]] = row[:position]
      parent_to_child_id[row[:parent_id]] ||= []
      parent_to_child_id[row[:parent_id]] << row[:id]
    end

    result = []

    # Start with top-level records
    root_set = [nil]
    id_positions[nil] = 0

    while !root_set.empty?
      next_rec = root_set.shift
      if next_rec.nil?
        # Our first iteration.  Nothing to add yet.
      else
        result << next_rec
      end

      children = parent_to_child_id.fetch(next_rec, []).sort_by {|child| id_positions[child]}
      children.reverse.each do |child|
        root_set.unshift(child)
      end
    end

    [{'ref' => self.uri}] +
      result.map {|id| {'ref' => self.class.node_model.uri_for(self.class.node_type, id)}
    }
  end

  def transfer_to_repository(repository, transfer_group = [])
    obj = super
    
    # All records under this one will be transferred too
    
    children.each do |child|
      child.transfer_to_repository(repository, transfer_group + [self])
    end

    obj
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    obj = super

    trigger_index_of_entire_tree

    obj
  end


  def trigger_index_of_entire_tree
    self.class.node_model.
                filter(:root_record_id => self.id).
                update(:system_mtime => Time.now)
  end


  module ClassMethods

    def tree_of(root_type, node_type)
      @root_type = root_type
      @node_type = node_type
    end


    def root_type
      @root_type
    end


    def node_type
      @node_type
    end


    def node_model
      Kernel.const_get(node_type.to_s.camelize)
    end


    def assemble_tree(node, links, properties)
      result = properties[node].clone

      if !result.has_key?('has_children')
        result['has_children'] = !!links[node]
      end

      if links[node]
        result['children'] = links[node].sort_by(&:first).map do |position, child_id|
          assemble_tree(child_id, links, properties)
        end
      else
        result['children'] = []
      end

      result
    end


    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      jsons.zip(objs).each do |json, obj|
        json['tree'] = {'ref' => obj.uri + '/tree'}
      end

      jsons
    end


    def calculate_object_graph(object_graph, opts = {})
      object_graph.each do |model, id_list|
        next if self != model

        ids = node_model.any_repo.filter(:root_record_id => id_list).
                         select(:id).map {|row|
          row[:id]
        }

        object_graph.add_objects(node_model, ids)
      end

      super
    end
  end

end
