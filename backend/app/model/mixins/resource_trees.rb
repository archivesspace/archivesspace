module ResourceTrees

  def build_node_query
    node_query = super
    node_query.eager(:instance => :sub_container)
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
        instance.sub_container
      }.flatten.compact.map {|sub_container|
        properties = {}

        top_container = sub_container.related_records(:top_container_link)

        if (top_container)
          properties["type_1"] = top_container.type || "Container"
          properties["indicator_1"] = top_container.indicator
          if top_container.barcode
            properties["indicator_1"] += " [#{top_container.barcode}]"
          end
        end

        properties["type_2"] = BackendEnumSource.value_for_id("container_type",
                                                              sub_container.type_2_id)
        properties["indicator_2"] = sub_container.indicator_2
        properties["barcode_2"] = sub_container.barcode_2
        properties["type_3"] = BackendEnumSource.value_for_id("container_type",
                                                              sub_container.type_3_id)
        properties["indicator_3"] = sub_container.indicator_3

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
