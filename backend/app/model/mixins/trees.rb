module Trees

  def self.included(base)
    base.extend(ClassMethods)
  end


  def adopt_children(old_parent)
    self.class.node_model.
         this_repo.filter(:root_record_id => old_parent.id,
                          :parent_id => nil).each do |root_child|
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


  def publish!
    children.each do |child|
      child.publish!
    end

    super
  end


  def build_node_query
    self.class.node_model.this_repo.filter(:root_record_id => self.id)
  end


  def load_node_properties(node, properties)
    # Does nothing by default, but classes that use this mixin add their own
    # behaviour here.
  end


  def load_root_properties(properties)
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

    query.all.each do |node|
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
        :node_type => node_type.to_s
      }

      if ids_of_interest != :all
        properties[node.id]['has_children'] = !!has_children[node.id]
      end

      load_node_properties(node, properties)
    end

    result = {
      :title => self.title,
      :id => self.id,
      :node_type => root_type.to_s,
      :publish => self.respond_to?(:publish) ? self.publish===1 : true,
      :children => top_nodes.sort_by(&:first).map {|position, node| self.class.assemble_tree(node, links, properties)},
      :record_uri => self.class.uri_for(root_type, self.id)
    }

    load_root_properties(result)

    JSONModel("#{self.class.root_type}_tree".intern).from_hash(result, true, true)
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


    def sequel_to_jsonmodel(obj, opts = {})
      json = super
      json['tree'] = {'ref' => obj.uri + '/tree'}
      json
    end


    def prepare_for_deletion(dataset)
      dataset.select(:id).each do |record|
        node_model.this_repo.filter(:root_record_id => record.id,
                                    :parent_id => nil).
          select(:id).each do |subrecord|
          subrecord.delete
        end
      end

      super
    end
  end


  def transfer_to_repository(repository, transfer_group = [])
    # All records under this one will be transferred too
    children.each do |child|
      child.transfer_to_repository(repository, transfer_group)
    end

    super
  end

end
