class TreeReordering

  @reorder_hooks = []

  def self.reorder_hooks
    @reorder_hooks
  end

  def self.add_after_reorder_hook(&block)
    @reorder_hooks << block
  end

  def reorder(target_class, child_class,
              target_id, child_ids,
              position)

    target = target_class.get_or_die(target_id)

    unless child_ids.empty?
      parent_id = (target_class == child_class) ? target_id : nil

      if target_class == child_class
        # If any of the children being dropped is an ancestor of the current node,
        # that's not OK.  No being your own grandfather!
        ancestor = target
        loop do
          break unless ancestor.parent_id
          ancestor = target_class.get_or_die(ancestor.parent_id)

          if child_ids.include?(ancestor.id)
            raise ConflictException.new("Can't make a parent into its own child")
          end
        end
      end

      # This has been flipped.  Due to changes in the tree_nodes, the values should
      # be processed using the lowest to highest.  This reverses the previous process
      # Does this cause any undo problems?
      first_id = child_ids[0]
      first_obj = child_class.get_or_die(first_id)

      # ok, we are keeping it in the same parent and moving down the list, we
      # need to reverse to make sure the placement happens correctly.
      # If the first_obj doesn't have a parent_id, that means it's at the top
      # of the food chain, so we can check if the target is a Tree, not a TreeNode.
      # Otherwise, we are moving into another parent.
      if (target.id == first_obj.parent_id || (target.class.included_modules.include?(Trees) && first_obj.parent_id.nil?)) && first_obj.logical_position < position
        ordered = child_ids.each_with_index.to_a.reverse
      else
        ordered = child_ids.each_with_index
      end

      last_child = nil
      ordered.each do |child_id, i|
        last_child = child_class.get_or_die(child_id)
        last_child.set_parent_and_position(parent_id, position + i)
      end
    end

    self.class.reorder_hooks.each do |hook|
      hook.call(target_class, child_class, target_id, child_ids, position)
    end

    target
  end

end
