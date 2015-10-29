module ResourceTrees
  alias_method :set_node_instances_pre_container_management, :set_node_instances
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
          properties["type_1"] = "Container"
          properties["indicator_1"] = top_container.indicator
          if top_container.barcode
            properties["indicator_1"] += " [#{top_container.barcode}]"
          end
        end

        properties["type_2"] = BackendEnumSource.value_for_id("container_type",
                                                              sub_container.type_2_id)
        properties["indicator_2"] = sub_container.indicator_2
        properties["type_3"] = BackendEnumSource.value_for_id("container_type",
                                                              sub_container.type_3_id)
        properties["indicator_3"] = sub_container.indicator_3

        properties
      }
    end
  end
end
