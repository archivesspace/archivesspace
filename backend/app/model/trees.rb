module Trees

  def self.included(base)
    base.extend(ClassMethods)
  end


  def tree
    links = {}
    properties = {}

    root_type = self.class.root_type
    node_type = self.class.node_type

    top_nodes = []
    Kernel.const_get(node_type.to_s.camelize).this_repo.filter("root_record_id".intern => self.id).each do |node|
      if node.parent_id
        links[node.parent_id] ||= []
        links[node.parent_id] << [node.position, node.id]
      else
        top_nodes << [node.position, node.id]
      end

      properties[node.id] = {
        :title => node.title,
        :id => node.id,
        :record_uri => self.class.uri_for(node_type, node.id),
        :node_type => node_type.to_s
      }
    end

    result = {
      :title => self.title,
      :id => self.id,
      :node_type => root_type.to_s,
      :children => top_nodes.sort_by(&:first).map {|position, node| self.class.assemble_tree(node, links, properties)},
      :record_uri => self.class.uri_for(root_type, self.id)
    }

    result
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

  end

end
