module Trees

  NODE_PAGE_SIZE = 2000

  def self.included(base)
    base.extend(ClassMethods)
  end


  def adopt_children(old_parent)
    self.class.node_model.this_repo
      .filter(:root_record_id => old_parent.id,
              :parent_id => nil)
      .order(:position).each do |root_child|
      root_child.set_root(self)
    end
  end


  def assimilate(merge_candidates)
    merge_candidates.each do |merge_candidate|
      adopt_children(merge_candidate)
    end

    Event.for_archival_record_merge(self, merge_candidates)

    super
  end


  def children
    self.class.node_model.
           this_repo.filter(:root_record_id => self.id,
                            :parent_id => nil)
  end


  def children?
    self.class.node_model.
      this_repo.filter(:root_record_id => self.id,
                       :parent_id => nil)
               .count > 0
  end


  def build_node_query
    self.class.node_model.this_repo.filter(:root_record_id => self.id)
  end


  def load_node_properties(node, properties, ids_of_interest = :all)
    # Does nothing by default, but classes that use this mixin add their own
    # behaviour here.
  end


  def load_root_properties(properties, ids_of_interest = :all)
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


  def tree(ids_of_interest = :all, display_mode = :full)
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

    offset = 0
    while true
      nodes = query.limit(NODE_PAGE_SIZE, offset).all

      nodes.each do |node|
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
          :suppressed => node.respond_to?(:suppressed) ? node.suppressed===1 : false,
          :node_type => node_type.to_s
        }

        if ids_of_interest != :all
          properties[node.id]['has_children'] = !!has_children[node.id]
        end

        unless display_mode == :sparse
          load_node_properties(node, properties, ids_of_interest)
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
      :id => self.id,
      :node_type => root_type.to_s,
      :publish => self.respond_to?(:publish) ? self.publish===1 : true,
      :suppressed => self.respond_to?(:suppressed) ? self.suppressed===1 : false,
      :children => top_nodes.sort_by(&:first).map {|position, node| self.class.assemble_tree(node, links, properties)},
      :record_uri => self.class.uri_for(root_type, self.id)
    }

    unless display_mode == :sparse
      if self.respond_to?(:finding_aid_filing_title) && !self.finding_aid_filing_title.nil? && self.finding_aid_filing_title.length > 0
        result[:finding_aid_filing_title] = self.finding_aid_filing_title
      end

      load_root_properties(result, ids_of_interest)
    end

    JSONModel("#{self.class.root_type}_tree".intern).from_hash(result, true, true)
  end

  # Return a depth-first-ordered list of URIs under this tree (starting with the tree itself)
  def ordered_records
    if self.publish == 0 || self.suppressed == 1
      # The whole resource is excluded.
      return []
    end

    id_positions = {}
    id_display_strings = {}
    id_depths = {nil => 0}
    parent_to_child_id = {}

    # Any record that is either suppressed or unpublished will be excluded from
    # our results.  Descendants of an excluded record will also be excluded.
    excluded_rows = {}

    self.class.node_model
      .filter(:root_record_id => self.id)
      .select(:id, :position, :parent_id, :display_string, :publish, :suppressed).each do |row|
      id_positions[row[:id]] = row[:position]
      id_display_strings[row[:id]] = row[:display_string]
      parent_to_child_id[row[:parent_id]] ||= []
      parent_to_child_id[row[:parent_id]] << row[:id]

      if row[:publish] == 0 || row[:suppressed] == 1
        excluded_rows[row[:id]] = true
      end
    end

    excluded_rows = apply_exclusions_to_descendants(excluded_rows, parent_to_child_id)

    # Our ordered list of record IDs
    result = []

    # Start with top-level records
    root_set = [nil]
    id_positions[nil] = 0

    while !root_set.empty?
      next_rec = root_set.shift
      if next_rec.nil?
        # Our first iteration.  Nothing to add yet.
      else
        unless excluded_rows[next_rec]
          result << next_rec
        end
      end

      children = parent_to_child_id.fetch(next_rec, []).sort_by {|child| id_positions[child]}
      children.reverse.each do |child|
        id_depths[child] = id_depths[next_rec] + 1
        root_set.unshift(child)
      end
    end

    extra_root_properties = self.class.ordered_record_properties([self.id])
    extra_node_properties = self.class.node_model.ordered_record_properties(result)

    [{'ref' => self.uri,
      'display_string' => self.title,
      'depth' => 0}.merge(extra_root_properties.fetch(self.id, {}))] +
      result.map {|id| {
                    'ref' => self.class.node_model.uri_for(self.class.node_type, id),
                    'display_string' => id_display_strings.fetch(id),
                    'depth' => id_depths.fetch(id),
                  }.merge(extra_node_properties.fetch(id, {}))}
  end

  # Update `excluded_rows` to mark any descendant of an excluded record as
  # itself excluded.
  #
  # `excluded_rows` is a map whose keys are the IDs of records that have been
  # marked as excluded.  `parent_to_child_id` is a map of record IDs to their
  # immediate children's IDs.
  #
  def apply_exclusions_to_descendants(excluded_rows, parent_to_child_id)
    remaining = excluded_rows.keys

    while !remaining.empty?
      excluded_parent = remaining.shift
      parent_to_child_id.fetch(excluded_parent, []).each do |child_id|
        excluded_rows[child_id] = true
        remaining.push(child_id)
      end
    end

    excluded_rows
  end

  def transfer_to_repository(repository, transfer_group = [])
    obj = super

    # All records under this one will be transferred too

    children.each do |child|
      child.transfer_to_repository(repository, transfer_group + [self])
    end

    obj
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    obj = super

    trigger_index_of_entire_tree

    obj
  end


  def trigger_index_of_entire_tree
    self.class.node_model.
                filter(:root_record_id => self.id).
                update(:system_mtime => Time.now)
  end

  def bulk_archival_object_updater_quick_tree
    links = {}
    properties = {}

    root_type = self.class.root_type
    node_type = self.class.node_type

    top_nodes = []

    container_info = bulk_archival_object_updater_fetch_container_info

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

  private

  def bulk_archival_object_updater_containers_ds
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


  def bulk_archival_object_updater_fetch_container_info
    result = {}

    bulk_archival_object_updater_containers_ds.each do |row|
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


    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      jsons.zip(objs).each do |json, obj|
        json['tree'] = {'ref' => obj.uri + '/tree'}
      end

      jsons
    end


    def calculate_object_graph(object_graph, opts = {})
      object_graph.each do |model, id_list|
        next if self != model

        ids = node_model.any_repo.filter(:root_record_id => id_list).
                         select(:id).map {|row|
          row[:id]
        }

        object_graph.add_objects(node_model, ids)
      end

      super
    end

    # Default: to be overriden by implementing models
    def ordered_record_properties(record_ids)
      {}
    end
  end

end
