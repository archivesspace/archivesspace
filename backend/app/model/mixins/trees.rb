module Trees

  def self.included(base)
    base.extend(ClassMethods)
  end


  def children
    Kernel.const_get(self.class.node_type.to_s.camelize).
           this_repo.filter(:root_record_id => self.id,
                            :parent_id => nil)
  end


  def publish!
    children.each do |child|
      child.publish!
    end

    super
  end


  def tree
    links = {}
    properties = {}

    root_type = self.class.root_type
    node_type = self.class.node_type

    top_nodes = []

    node_class = Kernel.const_get(node_type.to_s.camelize)

    node_query = node_class.this_repo.filter(:root_record_id => self.id)
    node_query = node_query.eager(:instance => :container).all if node_class.associations().include?(:instance)
    node_query = node_query.eager(:file_version).all if node_class.associations().include?(:file_version)

    node_query.each do |node|
      if node.parent_id
        links[node.parent_id] ||= []
        links[node.parent_id] << [node.position, node.id]
      else
        top_nodes << [node.position, node.id]
      end

      properties[node.id] = {
        :title => node_type === :archival_object ? node.label : node.title,
        :id => node.id,
        :record_uri => self.class.uri_for(node_type, node.id),
        :publish => node.respond_to?(:publish) ? node.publish===1 : true,
        :node_type => node_type.to_s
      }

      properties[node.id][:level] = ((node.level === 'otherlevel') ? node.other_level : node.level) if node.respond_to?(:level)

      # for tree nodes with instances
      if node.respond_to?(:instance) && node.instance.length > 0
        properties[node.id][:instance_types] = node.instance.map{|instance| instance.values[:instance_type]}
        properties[node.id][:containers] = node.instance.collect{|instance| instance.container}.flatten.compact.map{|container| Container.to_jsonmodel(container, :skip_relationships => true)}
      end

      # for digital component tree nodes
      if node.respond_to?(:file_version)
        properties[node.id][:file_versions] = node.file_version.map{|file| FileVersion.to_jsonmodel(file, :skip_relationships => true)}
      end
    end

    result = {
      :title => self.title,
      :id => self.id,
      :node_type => root_type.to_s,
      :publish => self.respond_to?(:publish) ? self.publish===1 : true,
      :children => top_nodes.sort_by(&:first).map {|position, node| self.class.assemble_tree(node, links, properties)},
      :record_uri => self.class.uri_for(root_type, self.id)
    }

    result[:level] = ((self.level === 'otherlevel') ? self.other_level : self.level) if self.respond_to?(:level)

    if self.respond_to?(:instance) && self.instance.length > 0
      result[:instance_types] = self.instance.map{|instance| instance.values[:instance_type]}
      result[:containers] = self.instance.collect{|instance| instance.container}.flatten.compact.map{|container| Container.to_jsonmodel(container, :skip_relationships => true)}
    end

    if self.respond_to?(:digital_object_type)
      result[:digital_object_type] = self.values[:digital_object_type]
    end

    if self.respond_to?(:file_version)
      result[:file_versions] = self.file_version.map{|file| FileVersion.to_jsonmodel(file, :skip_relationships => true)}
    end

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
        Kernel.const_get(node_type.to_s.camelize).
               this_repo.filter(:root_record_id => record.id, :parent_id => nil).select(:id).each do |subrecord|
          subrecord.delete
        end
      end

      super
    end
  end

end
