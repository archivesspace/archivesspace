# Mixin methods for objects that belong in an ordered hierarchy (archival
# objects, digital object components)

module TreeNodes

  # We'll space out our positions by this amount.  This means we can insert
  # log2(POSITION_STEP) nodes before any given node before needing to rebalance.
  #
  # Sized according to the largest number of nodes we think we might see under a
  # single parent.  The size of the position column is 2^31, so position can be
  # anywhere up to about 2 billion.  For a step size of 1000, that means we can
  # support (/ (expt 2 31) 1000) positions (around 2 million) before running out
  # of numbers.
  #
  POSITION_STEP = 1000

  # The number of times we'll retry an update that might transiently fail due to
  # concurrent updates.
  DB_RETRIES = 100

  def self.included(base)
    base.extend(ClassMethods)
  end

  # Move this node (and all records under it) to a new tree.
  def set_root(new_root)
    self.root_record_id = new_root.id

    if self.parent_id.nil?
      # This top-level node has been moved to a new tree.  Append it to the end of the list.
      root_uri = self.class.uri_for(self.class.root_record_type.intern, self.root_record_id)
      self.parent_name = "root@#{root_uri}"

      self.position = self.class.next_position_for_parent(self.root_record_id, self.parent_id)
    end

    save
    refresh

    children.each do |child|
      child.set_root(new_root)
    end
  end


  def set_position_in_list(target_logical_position)
    self.class.retry_db_update do
      attempt_set_position_in_list(target_logical_position)
    end
  end


  # A note on terminology: a logical position refers to the position of a node
  # as observed by the user (0...RECORD_COUNT).  A physical position is the
  # position number stored in the database, which may have gaps.
  def attempt_set_position_in_list(target_logical_position)
    DB.open do |db|
      ordered_siblings = db[self.class.node_model.table_name].filter(
        :root_record_id => self.root_record_id, :parent_id => self.parent_id
      ).order(:position)
      siblings_count = ordered_siblings.count

      target_logical_position = [target_logical_position, siblings_count - 1].min

      current_physical_position = self.position
      current_logical_position = ordered_siblings.where { position < current_physical_position }.count

      # If we are already at the correct logical position, do nothing
      return if (target_logical_position == current_logical_position)

      # We'll determine which node will fall to the left of our moved node, and
      # which will fall to the right.  We're going to set our physical position to
      # the halfway point of those two nodes.  For example, if left node is
      # position 1000 and right node is position 2000, we'll take position 1500.
      # If there's no gap, we'll create one!
      #
      left_node_idx = target_logical_position - 1

      if current_logical_position < target_logical_position
        # If the node is being moved to the right, we need to adjust our index to
        # compensate for the fact that everything logically shifts to the left as we
        # pop it out.
        left_node_idx += 1
      end

      left_node_physical_position =
        if left_node_idx < 0
          # We'll be the first item in the list (nobody to the left of us)
          nil
        else
          ordered_siblings.offset(left_node_idx).get(:position)
        end

      right_node_idx = left_node_idx + 1

      right_node_physical_position =
        if right_node_idx >= siblings_count
          # We'll be the last item in the list (nobody to the right of us)
          nil
        else
          ordered_siblings.offset(right_node_idx).get(:position)
        end

      new_position =
        if left_node_physical_position.nil? && right_node_physical_position.nil?
          # We're first in the list!
          new_position = TreeNodes::POSITION_STEP
        else
          if right_node_physical_position.nil?
            # Add to the end
            left_node_physical_position + TreeNodes::POSITION_STEP
          else
            left_node_physical_position ||= 0

            if (right_node_physical_position - left_node_physical_position) <= 1
              # We need to create a gap to fit our moved node
              right_node_physical_position = ensure_gap(right_node_physical_position)
            end

            # Put the node we're moving halfway between the left and right nodes
            left_node_physical_position + ((right_node_physical_position - left_node_physical_position) / 2)
          end
        end

      self.class.dataset.db[self.class.table_name]
        .filter(:id => self.id)
        .update(:position => new_position,
                :system_mtime => Time.now)
    end
  end

  def ensure_gap(start_physical_position)
    siblings = self.class.dataset
               .filter(:root_record_id => self.root_record_id)
               .filter(:parent_id => self.parent_id)
               .filter { position >= start_physical_position }

    # Sigh.  Work around:
    # http://stackoverflow.com/questions/5403437/atomic-multi-row-update-with-a-unique-constraint
    siblings.update(:parent_name => Sequel.lit(DB.concat('CAST(id as CHAR(10))', "'_temp'")))

    # Do the real update
    siblings.update(:position => Sequel.lit('position + ' + TreeNodes::POSITION_STEP.to_s),
                    :system_mtime => Time.now)

    # Puts it back again
    siblings.update(:parent_name => self.parent_name)

    start_physical_position + TreeNodes::POSITION_STEP
  end


  def logical_position
    relative_position = self.position
    self.class.dataset.filter(
      :root_record_id => self.root_record_id, :parent_id => self.parent_id
    ).where { position < relative_position }.count
  end


  def update_from_json(json, extra_values = {}, apply_nested_records = true)
    root_uri = self.class.uri_for(self.class.root_record_type, self.root_record_id)

    do_position_override = json[self.class.root_record_type]['ref'] != root_uri || extra_values[:force_reposition]

    if do_position_override
      extra_values.delete(:force_reposition)
      json.position = nil
      # Through some inexplicable sequence of events, the update is allowed to
      # change the root record on the fly.  I guess we'll allow this...
      extra_values = extra_values.merge(self.class.determine_tree_position_for_new_node(json))
    else
      # ensure we retain the current (physical) position when updating the record
      extra_values['position'] = self.position
    end

    obj = super(json, extra_values, apply_nested_records)

    if json.position
      # Our incoming JSON wants to set the position.  That's fine
      set_position_in_list(json.position)
    end

    self.class.ensure_consistent_tree(obj)

    trigger_index_of_child_nodes

    obj
  end


  def trigger_index_of_child_nodes
    self.children.update(:system_mtime => Time.now)
    self.children.each(&:trigger_index_of_child_nodes)
  end


  def set_parent_and_position(parent_id, position)
    self.class.retry_db_update do
      attempt_set_parent_and_position(parent_id, position)
    end
  end


  def attempt_set_parent_and_position(parent_id, position)
    root_uri = self.class.uri_for(self.class.root_record_type.intern, self[:root_record_id])

    if self.id == parent_id
      raise "Can't make a record into its own parent"
    end

    parent_name = if parent_id
                    "#{parent_id}@#{self.class.node_record_type}"
                  else
                    "root@#{root_uri}"
                  end

    new_values = {
      :parent_id => parent_id,
      :parent_name => parent_name,
      :system_mtime => Time.now
    }

    if parent_name == self.parent_name
      # Position is unchanged initially
      new_values[:position] = self.position
    else
      # Append this node to the new parent initially
      new_values[:position] = self.class.next_position_for_parent(root_record_id, parent_id)
    end

    # Run through the standard validation without actually saving
    self.set(new_values)
    self.validate

    if self.errors && !self.errors.empty?
      raise Sequel::ValidationFailed.new(self.errors)
    end

    self.class.dataset.filter(:id => self.id).update(new_values)
    self.refresh

    self.set_position_in_list(position)
  end


  def children
    self.class.filter(:parent_id => self.id).order(:position)
  end


  def has_children?
    self.class.filter(:parent_id => self.id).count > 0
  end


  def previous_node
    pos = self.position
    node = self.class.filter(:parent_id => self.parent_id)
                     .filter(:root_record_id => self.root_record_id)
                     .where { position < pos }
                     .reverse(:position).limit(1).first

    if !node && !self.parent_id
      raise NotFoundException.new("No previous node")
    end

    node || self.class[self.parent_id]
  end


  def transfer_to_repository(repository, transfer_group = [])
    # All records under this one will be transferred too
    children.each_with_index do |child, i|
      child.transfer_to_repository(repository, transfer_group + [self])
    end

    # ensure that the sequence if updated
    super
  end


  module ClassMethods

    def retry_db_update(&block)
      finished = false
      last_error = nil

      TreeNodes::DB_RETRIES.times do
        break if finished

        DB.attempt {
          block.call
          return
        }.and_if_constraint_fails {|err|
          last_error = err
        }
      end

      raise last_error
    end

    def tree_record_types(root, node)
      @root_record_type = root.to_s
      @node_record_type = node.to_s
    end

    def root_record_type
      @root_record_type
    end

    def node_record_type
      @node_record_type
    end


    def root_model
      Kernel.const_get(root_record_type.camelize)
    end


    def node_model
      Kernel.const_get(node_record_type.camelize)
    end

    def ensure_consistent_tree(obj)
      if obj.parent_id
        parent_root_record_id = node_model.filter(:id => obj.parent_id).get(:root_record_id)
        unless obj.root_record_id == parent_root_record_id
          raise "Consistency check failed: " \
                "#{node_model} #{obj.id} is in #{root_model} #{obj.root_record_id}," \
                " but its parent is in #{root_model} #{parent_root_record_id}."
        end
      end
    end

    def create_from_json(json, extra_values = {})
      obj = nil

      retry_db_update do
        DB.open do
          position_values = determine_tree_position_for_new_node(json)
          obj = super(json, extra_values.merge(position_values))
        end
      end

      if obj.nil?
        Log.error("Failed to set the position for #{node_model}: #{last_error}")
        raise last_error
      end

      migration = extra_values[:migration] ? extra_values[:migration].value : false
      if json.position && !migration
        obj.set_position_in_list(json.position)
      end

      ensure_consistent_tree(obj)

      obj
    end


    def determine_tree_position_for_new_node(json)
      result = {}

      root_record_uri = json[root_record_type]['ref']
      result["root_record_id"] = JSONModel.parse_reference(root_record_uri).fetch(:id)

      # 'parent_name' is a bit funny.  We need this column because the combination
      # of (parent, position) needs to be unique, to ensure that two siblings
      # don't occupy the same position when ordering them.  However, parent_id can
      # be NULL, meaning that the current node is at the top level of the tree.
      # This prevents the uniqueness check for working against top-level elements.
      #
      # So, parent_name gets used as a stand in in this case: it always has a
      # value for any node belonging to a hierarchy, and this value gets used in
      # the uniqueness check.
      #
      if json.parent
        parent_id = JSONModel.parse_reference(json.parent['ref']).fetch(:id)

        result["parent_id"] = parent_id
        result["parent_name"] = "#{parent_id}@#{self.node_record_type}"
      else
        result["parent_id"] = nil
        result["parent_name"] = "root@#{root_record_uri}"
      end

      # We'll add this new node to the end of the list.  To do that, find the
      # maximum position assigned so far and go TreeNodes::POSITION_STEP places
      # after that.  If another create_from_json gets in first, we'll have to
      # retry, but that's fine.
      result["position"] = next_position_for_parent(result['root_record_id'], result['parent_id'])

      result
    end

    def next_position_for_parent(root_record_id, parent_id)
      max_position = DB.open do |db|
        db[node_model.table_name]
          .filter(:root_record_id => root_record_id, :parent_id => parent_id)
          .select(:position)
          .max(:position)
      end
      max_position ||= 0

      max_position + TreeNodes::POSITION_STEP
    end

    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      jsons.zip(objs).each do |json, obj|
        if obj.root_record_id
          json[root_record_type] = {'ref' => uri_for(root_record_type, obj.root_record_id)}

          if obj.parent_id
            json.parent = {'ref' => uri_for(node_record_type, obj.parent_id)}
          end

          if obj.parent_name
            # Calculate the logical (gapless) position of this node.  This
            # bridges the gap between the DB's view of position, which only
            # cares that the positions order correctly, with the API's view,
            # which speaks in logical numbering (i.e. the first position is 0,
            # the second position is 1, etc.)

            json.position = obj.logical_position
          end

        end

        if node_model.publishable?
          json['has_unpublished_ancestor'] = calculate_has_unpublished_ancestor(obj)
        end
      end

      jsons
    end


    def calculate_has_unpublished_ancestor(obj, check_root_record = true)
      if check_root_record && obj.root_record_id
        root = root_model[obj.root_record_id]
        return true if root.publish == 0 || root.suppressed == 1
      end

      if obj.parent_id
        parent = node_model[obj.parent_id]
        if parent.publish == 0 || parent.suppressed == 1
          return true
        else
          return calculate_has_unpublished_ancestor(parent, false)
        end
      end

      false
    end


    def calculate_object_graph(object_graph, opts = {})
      object_graph.each do |model, id_list|
        next if self != model

        ids = self.any_repo.filter(:parent_id => id_list).
                   select(:id).map {|row|
          row[:id]
        }

        object_graph.add_objects(self, ids)
      end

      super
    end


    def handle_delete(ids_to_delete)
      ids = self.filter(:id => ids_to_delete )

      # Update the root record's mtime so that any tree-related records are reindexed
      root_model.filter(:id => ids.select(:root_record_id)).update(:system_mtime => Time.now)

      # lets get a group of records that have unique parents or root_records
      parents = ids.select_group(:parent_id, :root_record_id).all
      # we then nil out the parent id so deletes can do its thing
      ids.update(:parent_id => nil)
      # trigger the deletes...
      super
    end

    # Default: to be overriden by implementing models
    def ordered_record_properties(record_ids)
      {}
    end
  end

end
