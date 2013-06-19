module ResourceTrees

  def build_node_query
    node_query = super
    node_query.eager(:instance => :container).all
  end


  def set_node_level(node, properties)
    if node.level === 'otherlevel'
      properties[:level] = node.other_level
    else
      properties[:level] = node.level
    end
  end


  def set_node_instances(node, properties)
    if node.instance.length > 0
      properties[:instance_types] = node.instance.map {|instance|
        instance.values[:instance_type]
      }

      properties[:containers] = node.instance.collect {|instance|
        instance.container
      }.flatten.compact.map {|container|
        Container.to_jsonmodel(container, :skip_relationships => true)
      }
    end
  end


  def load_node_properties(node, properties)
    super

    properties[node.id][:title] = node.label

    set_node_level(node, properties[node.id])
    set_node_instances(node, properties[node.id])
  end


  def load_root_properties(properties)
    super

    set_node_level(self, properties)
    set_node_instances(self, properties)
  end

end
