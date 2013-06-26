# Mixin methods for objects that belong in an ordered hierarchy (archival
# objects, digital object components)
require 'securerandom'

module Orderable

  def self.included(base)
    base.extend(ClassMethods)
  end


  def set_root(new_root)
    self.root_record_id = new_root.id
    save
    refresh

    if self.parent_id.nil?
      # Set ourselves to the end of the list
      update_position_only(nil, nil)
    end

    children.each do |child|
      child.set_root(new_root)
    end
  end


  def set_position_in_list(target_position, sequence)
    siblings_ds = self.class.dataset.
                       filter(:root_record_id => self.root_record_id,
                              :parent_id => self.parent_id,
                              ~:position => nil)

    # Find the position of the element we'll be inserted after.  If there are no
    # elements, or if our target position is zero, then we'll get inserted at
    # position zero.
    predecessor = if target_position > 0
                    siblings_ds.filter(~:id => self.id).order(:position).limit(target_position).select(:position).all
                  else
                    []
                  end

    new_position = !predecessor.empty? ? (predecessor.last[:position] + 1) : 0

    100.times do
      DB.attempt {
        # Go right to the database here to avoid bumping lock_version for tree changes.
        self.class.dataset.db[self.class.table_name].filter(:id => self.id).update(:position => new_position)
        return
      }.and_if_constraint_fails {
        # Someone's in our spot!  Move everyone out of the way and retry.

        # Bump the sequence to maintain the invariant that sequence.number >= max(position)
        # (since we're about to increment the last N positions by 1)
        Sequence.get(sequence)

        # Sigh.  Work around:
        # http://stackoverflow.com/questions/5403437/atomic-multi-row-update-with-a-unique-constraint

        # Disables the uniqueness constraint
        siblings_ds.
        filter { position >= new_position }.
        update(:parent_name => Sequel.lit(DB.concat('CAST(id as CHAR(10))', "'_temp'")))

        # Do the update we actually wanted
        siblings_ds.
        filter { position >= new_position }.
        update(:position => Sequel.lit('position + 1'))

        # Puts it back again
        siblings_ds.
        filter { position >= new_position }.
        update(:parent_name => self.parent_name)

        # Now there's a gap at new_position ready for our element.
      }
    end

    raise "Failed to set the position for #{self}"
  end


  def update_from_json(json, opts = {}, apply_linked_records = true)
    sequence = self.class.sequence_for(json)

    self.class.set_root_record(json, sequence, opts)

    obj = super

    # Then lock in a position (which may involve contention with other updates
    # happening to the same tree of records)
    if json[self.class.root_record_type] && json.position
      self.set_position_in_list(json.position, sequence)
    end

    obj
  end


  def update_position_only(parent_id, position)
    if self[:root_record_id]
      root_uri = self.class.uri_for(self.class.root_record_type.intern, self[:root_record_id])
      parent_uri = parent_id ? self.class.uri_for(self.class.node_record_type.intern, parent_id) : nil
      sequence = "#{root_uri}_#{parent_uri}_children_position"

      parent_name = if parent_id
                      "#{parent_id}@#{self.class.node_record_type}"
                    else
                      "root@#{root_uri}"
                    end

      new_values = {
        :parent_id => parent_id,
        :parent_name => parent_name,
        :position => Sequence.get(sequence),
        :system_mtime => Time.now
      }

      # Run through the standard validation without actually saving
      self.set(new_values)
      self.validate

      if self.errors && !self.errors.empty?
        raise Sequel::ValidationFailed.new(self.errors)
      end

      # Now do the update (without touching lock_version)
      self.class.dataset.filter(:id => self.id).update(new_values)

      self.refresh
      self.set_position_in_list(position, sequence) if position
    else
      raise "Root not set for record #{self}"
    end
  end


  def children
    self.class.filter(:parent_id => self.id).order(:position)
  end


  def publish!
    children.each do |child|
      child.publish!
    end

    super
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


    def sequence_for(json)
      if json[root_record_type]
        if json.parent
          "#{json[root_record_type]['ref']}_#{json.parent['ref']}_children_position"
        else
          "#{json[root_record_type]['ref']}__children_position"
        end
      end
    end

    def create_from_json(json, opts = {})
      sequence = sequence_for(json)
      set_root_record(json, sequence, opts)

      obj = super

      if json[self.root_record_type] && json.position
        obj.set_position_in_list(json.position, sequence)
      end

      obj
    end


    def set_root_record(json, sequence, opts)
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
        opts["root_record_id"] = parse_reference(json[root_record_type]['ref'], opts)[:id]

        if json.parent
          opts["parent_id"] = parse_reference(json.parent['ref'], opts)[:id]
          opts["parent_name"] = "#{opts['parent_id']}@#{self.node_record_type}"
        else
          opts["parent_name"] = "root@#{json[root_record_type]['ref']}"
        end

        opts["position"] = Sequence.get(sequence)

      else
        # This record isn't part of a tree hierarchy
        opts["parent_name"] = "orphan@#{SecureRandom.uuid}"
        opts["position"] = 0
      end
    end


    def sequel_to_jsonmodel(obj, opts = {})
      json = super

      if obj.root_record_id
        json[root_record_type] = {'ref' => uri_for(root_record_type, obj.root_record_id)}

        if obj.parent_id
          json.parent = {'ref' => uri_for(node_record_type, obj.parent_id)}
        end
      end

      json
    end


    def prepare_for_deletion(dataset)
      dataset.select(:id).each do |record|
        self.filter(:parent_id => record.id).select(:id).each do |victim|
          victim.delete
        end
      end

      super
    end

  end


  def transfer_to_repository(repository, transfer_group = [])
    # All records under this one will be transferred too
    children.each do |child|
      child.transfer_to_repository(repository, transfer_group)
    end

    super
  end

end
