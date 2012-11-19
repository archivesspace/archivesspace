# Mixin methods for objects that belong in an ordered hierarchy (archival
# objects, digital object components)

module Orderable

  def self.included(base)
    base.extend(ClassMethods)
  end


  def set_position_in_list(old_position, target_position)

    100.times do
      begin
        self.update(:position => target_position)
        self.save
        return
      rescue Sequel::DatabaseError => e
        if DB.is_integrity_violation(e)
          # Someone's in our spot!  Move everyone out of the way.
          if old_position && old_position < target_position
            # Shift everyone left
            self.class.dataset.
                 filter(:parent_id => self.parent_id).
                 filter { position <= target_position }.
                 update(:position => Sequel.lit('position - 1'))

          else
            # Shift everyone right
            self.class.dataset.
                 filter(:parent_id => self.parent_id).
                 filter { position >= target_position }.
                 update(:position => Sequel.lit('position + 1'))
          end
        end
      end
    end

    raise "Failed to set the position for #{self}"
  end


  def update_from_json(json, opts = {})

    self.class.set_root_record(json, opts)

    # Initially save the object with no position set, and we'll negotiate it afterwards.
    old_position = self.position
    opts["position"] = nil

    obj = super

    if json[self.class.root_record_type]

      if !json.position
        json.position = Sequence.get("#{json[self.class.root_record_type]}_#{json.parent}_children_position")
      end

      self.set_position_in_list(old_position, json.position)
    end

    obj
  end


  def children
    self.class.filter(:parent_id => self.id).order(:position)
  end


  def has_children?
    self.class.filter(:parent_id => self.id).count > 0
  end



  module ClassMethods

    def orderable_root_record_type(root, node)
      @root_record_type = root.to_s
      @node_record_type = node.to_s
    end

    def root_record_type
      @root_record_type
    end

    def node_record_type
      @node_record_type
    end


    def create_from_json(json, opts = {})
      set_root_record(json, opts)

      if json[root_record_type]
        # This new record is a member of a hierarchy, so add it to the end of its siblings
        json.position = Sequence.get("#{json[root_record_type]}_#{json.parent}_children_position")
      end

      super
    end


    def set_root_record(json, opts)
      opts["root_record_id"] = nil
      opts["parent_id"] = nil
      opts["parent_name"] = nil

      # 'parent_name' is a bit funny.  We need this column because the combination
      # of (parent, position) needs to be unique, to ensure that two siblings
      # don't occupy the same position when ordering them.  However, parent_id can
      # be NULL, meaning that the current node is at the top level of the tree.
      # This prevents the uniqueness check for working against top-level elements.
      #
      # So, parent_name gets used as a stand in in this case: it always has a
      # value for any node belonging to a hierarchy, and this value gets used in
      # the uniqueness check.

      if json[root_record_type]
        opts["root_record_id"] = JSONModel::parse_reference(json[root_record_type], opts)[:id]

        if json.parent
          opts["parent_id"] = JSONModel::parse_reference(json.parent, opts)[:id]
          opts["parent_name"] = opts["parent_id"].to_s
        else
          opts["parent_name"] = "(root)"
        end
      end
    end


    def sequel_to_jsonmodel(obj, type, opts = {})
      json = super

      if obj.root_record_id
        json[root_record_type] = uri_for(root_record_type, obj.root_record_id)

        if obj.parent_id
          json.parent = uri_for(node_record_type, obj.parent_id)
        end
      end

      json
    end


  end

end
