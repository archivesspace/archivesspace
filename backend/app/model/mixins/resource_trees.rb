module ResourceTrees

  def build_node_query
    node_query = super
    node_query.eager(:instance => :container)
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
        properties = {}
        [1, 2, 3].each do |i|
          properties["type_#{i}"] = BackendEnumSource.value_for_id("container_type",
                                                                   container["type_#{i}_id".intern])

          properties["indicator_#{i}"] = container["indicator_#{i}".intern]
        end

        properties
      }
    end
  end


  # If we're being asked to load an entire tree, don't bother loading all of the
  # instances that go with each node.  This is a performance optimisation, since
  # there can be tens of thousands of instances.  The only place that pulls down
  # the entire tree is the indexer, and it doesn't need instance/container
  # information from the tree anyway.

  def load_node_properties(node, properties, ids_of_interest = :all)
    super

    properties[node.id][:title] = node.display_string
    properties[node.id][:component_id] = node.component_id if node.component_id

    set_node_level(node, properties[node.id])
    set_node_instances(node, properties[node.id]) #if ids_of_interest != :all
  end


  def load_root_properties(properties, ids_of_interest = :all)
    super

    set_node_level(self, properties)
    set_node_instances(self, properties) if ids_of_interest != :all
  end

end
