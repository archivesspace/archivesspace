module Trees
  def quick_tree
    links = {}
    properties = {}

    root_type = self.class.root_type
    node_type = self.class.node_type

    top_nodes = []

    container_info = fetch_container_info

    query = build_node_query

    offset = 0
    loop do
      nodes = query.limit(NODE_PAGE_SIZE, offset)

      nodes.each do |node|
        if node.parent_id
          links[node.parent_id] ||= []
          links[node.parent_id] << [node.position, node.id]
        else
          top_nodes << [node.position, node.id]
        end

        properties[node.id] = {
          :title => node.display_string,
          :uri => self.class.uri_for(node_type, node.id),
          :ref_id => node[:ref_id],
          :component_id => node[:component_id],
          :container => container_info.fetch(node.id, nil),
        }

        # Drop out nils to keep the object size as small as possible
        properties[node.id].keys.each do |key|
          properties[node.id].delete(key) if properties[node.id][key].nil?
        end
      end

      if nodes.empty?
        break
      else
        offset += NODE_PAGE_SIZE
      end
    end

    result = {
      :title => self.title,
      :identifier => Identifiers.format(Identifiers.parse(self.identifier)),
      :children => top_nodes.sort_by(&:first).map {|_, node| self.class.assemble_tree(node, links, properties)},
      :uri => self.class.uri_for(root_type, self.id)
    }

    result
  end


  def quick_containers
    result = {}
    containers_ds.each do |row|
      fields = {}
      fields[:top_container] = {
        :type => row[:top_container_type],
        :indicator => row[:top_container_indicator],
        :barcode => row[:top_container_barcode]
      }
      fields[:sub_container] = {
        :type_2 => row[:sub_container_type_2],
        :indicator_2 => row[:sub_container_indicator_2],
        :type_3 => row[:sub_container_type_3],
        :indicator_3 => row[:sub_container_indicator_3],
      }
      result[row[:archival_object_id]] ||= []
      result[row[:archival_object_id]] << fields
    end
    result
  end


  private

  def containers_ds
    TopContainer.linked_instance_ds
      .join(:archival_object, :id => :instance__archival_object_id)
      .left_join(:enumeration_value___top_container_type, :id => :top_container__type_id)
      .left_join(:enumeration_value___sub_container_type_2, :id => :sub_container__type_2_id)
      .left_join(:enumeration_value___sub_container_type_3, :id => :sub_container__type_3_id)
      .filter(:archival_object__root_record_id => self.id)
      .select(Sequel.as(:archival_object__id, :archival_object_id),
              Sequel.as(:top_container__barcode, :top_container_barcode),
              Sequel.as(:top_container_type__value, :top_container_type),
              Sequel.as(:top_container__indicator, :top_container_indicator),
              Sequel.as(:sub_container_type_2__value, :sub_container_type_2),
              Sequel.as(:sub_container__indicator_2, :sub_container_indicator_2),
              Sequel.as(:sub_container_type_3__value, :sub_container_type_3),
              Sequel.as(:sub_container__indicator_3, :sub_container_indicator_3))
  end


  def fetch_container_info
    result = {}

    containers_ds.each do |row|
      result[row[:archival_object_id]] = [
        # BoxType Indicator [Barcode]
        [row[:top_container_type],
         row[:top_container_indicator],
         row[:top_container_barcode] ? ('[' + row[:top_container_barcode] + ']') : nil].compact.join(': '),

        # BoxType_2 Indicator_2
        [row[:sub_container_type_2], row[:sub_container_indicator_2]].compact.join(': '),

        # BoxType_3 Indicator_3
        [row[:sub_container_type_3], row[:sub_container_indicator_3]].compact.join(': '),
      ].reject(&:empty?).join(', ')
    end

    result
  end
end
