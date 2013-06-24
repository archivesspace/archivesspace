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


  def tree
    links = {}
    properties = {}

    root_type = self.class.root_type
    node_type = self.class.node_type

    top_nodes = []

    build_node_query.each do |node|
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

    # Assumes that the tree's JSONModel type is just the root type with '_tree'
    # stuck on.  Maybe a bit presumptuous?
    JSONModel("#{self.class.root_type}_tree".intern).from_hash(result)
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

end
