# Mixin methods for objects that belong in an ordered hierarchy (archival
# objects, digital object components)
require 'securerandom'

module TreeNodes

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
    else
      update_position_only(self.parent_id, self.position)
    end

    children.each do |child|
      child.set_root(new_root)
    end
  end
 

  def siblings
    self.class.dataset.
       filter(:root_record_id => self.root_record_id,
              :parent_id => self.parent_id,
              ~:position => nil)
  end


  # this is just a CYA method, that might be removed in the future. We need to
  # be sure that all the positional gaps.j
  def order_siblings
    # add this to avoid DB constraints 
    siblings.update(:parent_name => Sequel.lit(DB.concat('CAST(id as CHAR(10))', "'_temp'")))
   
    # get set a list of ids and their order based on their position
    position_map = siblings.select(:id).order(:position).each_with_index.inject({}) { |m,( obj, index) | m[obj[:id]] = index; m }
    
    # now we do the update in batches of 200 
    position_map.each_slice(200) do |pm|
      # the slice reformat the hash...so quickly format it back 
      pm = pm.inject({}) { |m,v| m[v.first] = v.last; m } 
      # this ids that we're updating in this batch 
      sibling_ids = pm.keys 
     
      # the resulting update will look like:
      #  UPDATE "ARCHIVAL_OBJECT" SET "POSITION" = (CASE WHEN ("ID" = 10914)
      #  THEN 0 WHEN ("ID" = 10915) THEN 1 WHEN ("ID" = 10912) THEN 2 WHEN
      #  ("ID" = 10913) THEN 3 WHEN ("ID" = 10916) THEN 4 WHEN ("ID" = 10921)
      #  THEN 5 WHEN ("ID" = 10917) THEN 6 WHEN ("ID" = 10920) THEN 7 ELSE 0
      #  END) WHERE (("ROOT_RECORD_ID" = 3) AND ("PARENT_ID" = 10911) AND (NOT
      #  "POSITION" IS NULL) AND ("ID" IN (10914, 10915, 10912, 10913, 10916,
      #  10921, 10917, 10920))
      #  )
      # this should be faster than just iterating thru all the children,
      # since it does it in batches of 200 and limits the number of updates.  
      siblings.filter(:id => sibling_ids).update( :position => Sequel.case(pm, 0, :id) )
    end
   
    # now we return the parent_name back so our DB constraints are back on.:w
    siblings.update(:parent_name => self.parent_name )
  end

  def set_position_in_list(target_position, sequence)
    
    # Find the position of the element we'll be inserted after.  If there are no
    # elements, or if our target position is zero, then we'll get inserted at
    # position zero.
    predecessor = if target_position > 0
                    siblings.filter(~:id => self.id).order(:position).limit(target_position).select(:position).all
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
        siblings.
        filter { position >= new_position }.
        update(:parent_name => Sequel.lit(DB.concat('CAST(id as CHAR(10))', "'_temp'")))

        # Do the update we actually wanted
        siblings.
        filter { position >= new_position }.
        update(:position => Sequel.lit('position + 1')) 


        # Puts it back again
        siblings.
        filter { position >= new_position}.
        update(:parent_name => self.parent_name )
        # Now there's a gap at new_position ready for our element.
      }
    end

    raise "Failed to set the position for #{self}"
  end

  def absolute_position
    relative_position = self.position
    self.class.dataset.filter(:parent_name => self.parent_name).where { position < relative_position }.count
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    sequence = self.class.sequence_for(json)

    self.class.set_root_record(json, sequence, opts)

    obj = super

    # Then lock in a position (which may involve contention with other updates
    # happening to the same tree of records)
    if json[self.class.root_record_type] && json.position
      self.set_position_in_list(json.position, sequence)
    end

    trigger_index_of_child_nodes

    obj
  end


  def trigger_index_of_child_nodes
    self.children.update(:system_mtime => Time.now)
    self.children.each(&:trigger_index_of_child_nodes)
  end


  def update_position_only(parent_id, position)
    if self[:root_record_id]
      root_uri = self.class.uri_for(self.class.root_record_type.intern, self[:root_record_id])
      parent_uri = parent_id ? self.class.uri_for(self.class.node_record_type.intern, parent_id) : root_uri
      sequence = "#{parent_uri}_children_position"

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
    
     
      # let's try and update the position. If it doesn't work, then we'll fix 
      # the position when we set it in the list...there can be problems when
      # transfering to another repo when there's holes in the tree...
      DB.attempt {
        self.class.dataset.filter(:id => self.id).update(new_values)
      }.and_if_constraint_fails { 
        new_values.delete(:position) 
        self.class.dataset.filter(:id => self.id).update(new_values)
      }
     
      self.refresh
      self.set_position_in_list(position, sequence) if position
    else
      raise "Root not set for record #{self.inspect}"
    end
  end


  def children
    self.class.filter(:parent_id => self.id).order(:position)
  end


  def has_children?
    self.class.filter(:parent_id => self.id).count > 0
  end


  def transfer_to_repository(repository, transfer_group = [])
    
   
    # All records under this one will be transferred too
    children.each_with_index do |child, i|
      child.transfer_to_repository(repository, transfer_group + [self]) 
    #  child.update_position_only( child.parent_id, i ) 
    end
    
    RequestContext.open(:repo_id => repository.id ) do
      self.update_position_only(self.parent_id, self.position) unless self.root_record_id.nil?
    end
      
    # ensure that the sequence if updated 
    
    super 
  end


  module ClassMethods

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


    def sequence_for(json)
      if json[root_record_type]
        if json.parent
          "#{json.parent['ref']}_children_position"
        else
          "#{json[root_record_type]['ref']}_children_position"
        end
      end
    end

    def create_from_json(json, opts = {})
      sequence = sequence_for(json)
      set_root_record(json, sequence, opts)
     
      obj = super
     
      migration = opts[:migration] ? opts[:migration].value : false
      if json[self.root_record_type] && json.position && !migration 
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


    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      jsons.zip(objs).each do |json, obj|
        if obj.root_record_id
          json[root_record_type] = {'ref' => uri_for(root_record_type, obj.root_record_id)}

          if obj.parent_id
            json.parent = {'ref' => uri_for(node_record_type, obj.parent_id)}
          end

          if obj.parent_name
            # Calculate the absolute (gapless) position of this node.  This
            # bridges the gap between the DB's view of position, which only
            # cares that the positions order correctly, with the API's view,
            # which speaks in absolute numbering (i.e. the first position is 0,
            # the second position is 1, etc.)

            json.position = obj.absolute_position
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
        return true if root_model[obj.root_record_id].publish == 0
      end

      if obj.parent_id
        parent = node_model[obj.parent_id]
        if parent.publish == 0
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
      # lets get a group of records that have unique parents or root_records
      parents = ids.select_group(:parent_id, :root_record_id).all   
      # we then nil out the parent id so deletes can do its thing 
      ids.update(:parent_id => nil)
      # trigger the deletes... 
      obj = super
      # now lets make sure there are no holes
      parents.each do |parent|
       children = self.filter(:root_record_id => parent[:root_record_id], :parent_id => parent[:parent_id], ~:position => nil )  
       parent_name = children.get(:parent_name) 
       children.update(:parent_name => Sequel.lit(DB.concat('CAST(id as CHAR(10))', "'_temp'"))) 
       children.order(:position).each_with_index do |row, i|
        row.update(:position => i)
       end
       children.update(:parent_name => parent_name) 
      end
      obj
    end

    # this requences the class, which updates the Sequence with correct
    # sequences
    def resequence(repo_id)
      RequestContext.open(:repo_id => repo_id) do
        # get all the objects that are parents but not at top level or orphans 
        $stderr.puts "Resequencing for #{self.class.to_s} in repo #{repo_id}" 
        self.filter(~:position => nil, :repo_id => repo_id, ~:parent_id => nil, ~:root_record_id => nil ).select(:parent_id).group(:parent_id)
            .each do |obj| 
              $stderr.print "+" 
              self.filter(:parent_id => obj.parent_id).order(:position).each_with_index do |child, i| 
                $stderr.print "." 
                child.update_position_only(child.parent_id, i) 
            end 
        end 
        $stderr.puts "*"  
      end 
    end

  end

end
