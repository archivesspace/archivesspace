class AncestorListing

  # For a given set of Sequel `objs` and their corresponding `jsons` records,
  # walk back up the tree enumerating their ancestor records and add them as
  # refs to the `ancestors` JSON property.
  def self.add_ancestors(objs, jsons)
    return if objs.empty?

    node_class = objs[0].class
    ancestors = new(node_class, objs)

    jsons.zip(objs).each do |json, obj|
      json['ancestors'] = []

      current = obj
      while (parent = ancestors.parent_of(current.id))
        json['ancestors'] << {'ref' => parent.uri,
                              'level' => parent.level}
        current = parent
      end

      root = ancestors.root_record(obj[:root_record_id])
      json['ancestors'] << {
        'ref' => root.uri,
        'level' => root.level
      }
    end
  end


  def initialize(node_class, objs)
    @node_model = node_class
    @root_model = node_class.root_model

    @ancestors = {}
    @root_records = {}

    objs.each do |obj|
      @ancestors[obj.id] = {:id => obj.id,
                            :level => level_value(obj.level, obj.other_level),
                            :parent_id => obj.parent_id,
                            :root_record_id => obj.root_record_id}
    end

    build_ancestor_links
  end

  # The parent of the given node
  def parent_of(node_id)
    parent_id = @ancestors.fetch(node_id)[:parent_id]

    if parent_id
      ancestor = @ancestors.fetch(parent_id)

      Ancestor.new(ancestor[:id],
                   @node_model.uri_for(@node_model.my_jsonmodel.record_type, ancestor[:id]),
                   ancestor[:level])
    end
  end

  # The root record of the given node
  def root_record(root_record_id)
    root_record = @root_records.fetch(root_record_id)

    Ancestor.new(root_record[:id],
                 @root_model.uri_for(@root_model.my_jsonmodel.record_type, root_record[:id]),
                 root_record[:level])
  end

  private

  # Walk and record the ancestors of all records of interest
  def build_ancestor_links
    # Starting with our initial set of nodes, walk up the tree parent-by-parent
    # until we hit the top-level nodes.
    while true
      parent_ids_to_fetch = @ancestors.map {|_, ancestor|
        if ancestor[:parent_id] && !@ancestors[ancestor[:parent_id]]
          ancestor[:parent_id]
        end
      }.compact

      # Done!
      break if parent_ids_to_fetch.empty?

      @node_model
        .join(:enumeration_value, :enumeration_value__id => Sequel.qualify(@node_model.table_name, :level_id))
        .filter(Sequel.qualify(@node_model.table_name, :id) => parent_ids_to_fetch)
        .select(Sequel.qualify(@node_model.table_name, :id),
                :parent_id,
                :root_record_id,
                Sequel.as(:enumeration_value__value, :level),
                :other_level).each do |row|
        @ancestors[row[:id]] = {
          :id => row[:id],
          :level => level_value(row[:level], row[:other_level]),
          :parent_id => row[:parent_id],
          :root_record_id => row[:root_record_id]
        }
      end
    end

    # Now fetch the root record for each chain of record nodes
    root_record_ids = @ancestors.map {|_, ancestor| ancestor[:root_record_id]}.compact.uniq

    @root_model
      .join(:enumeration_value, :enumeration_value__id => Sequel.qualify(@root_model.table_name, :level_id))
      .filter(Sequel.qualify(@root_model.table_name, :id) => root_record_ids)
      .select(Sequel.qualify(@root_model.table_name, :id),
              Sequel.as(:enumeration_value__value, :level),
              :other_level).each do |row|
      @root_records[row[:id]] = {
          :id => row[:id],
          :level => level_value(row[:level], row[:other_level]),
      }
    end
  end

  Ancestor = Struct.new(:id, :uri, :level)

  def level_value(level, other_level)
    level == 'otherlevel' ? other_level : level
  end

end
