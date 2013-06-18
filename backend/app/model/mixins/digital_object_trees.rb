module DigitalObjectTrees

  def build_node_query
    node_query = super
    node_query.eager(:file_version).all
  end


  def set_file_version(node, properties)
    properties[:file_versions] = node.file_version.map{|file|
      FileVersion.to_jsonmodel(file, :skip_relationships => true)
    }
  end


  def load_node_properties(node, properties)
    super

    set_file_version(node, properties[node.id])
  end


  def load_root_properties(properties)
    super

    properties[:level] = self.level
    properties[:digital_object_type] = self.values[:digital_object_type]
    set_file_version(self, properties)
  end

end
