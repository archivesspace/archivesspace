# TODO: Some documentation on what's going on

class LargeTree

  include JSONModel

  WAYPOINT_SIZE = 200

  def initialize(root_record)
    @decorators = []

    @root_record = root_record

    @root_table = root_record.class.root_type.intern
    @node_table = @node_type = root_record.class.node_type.intern
  end

  def add_decorator(decorator)
    @decorators << decorator
  end

  def root
    DB.open do |db|
      child_count = db[@node_table].filter(:root_record_id => @root_record.id,
                                           :parent_id => nil)
                                   .count

      response = waypoint_response(child_count).merge("title" => @root_record.title,
                                                      "uri" => @root_record.uri)
      @decorators.each do |decorator|
        response = decorator.root(response, @root_record)
      end

      precalculate_waypoints(response, nil)

      response
    end
  end

  def node(node_record)
    DB.open do |db|
      child_count = db[@node_table]
                    .filter(:root_record_id => @root_record.id,
                            :parent_id => node_record.id)
                    .count

      response = waypoint_response(child_count).merge("title" => node_record.display_string,
                                                      "uri" => node_record.uri)

      @decorators.each do |decorator|
        response = decorator.node(response, node_record)
      end

      precalculate_waypoints(response, node_record.id)

      response
    end
  end

  def node_from_root(ao_id)
    result = []

    DB.open do |db|
      while true
        this_node = db[@node_table].filter(:id => ao_id).select(:repo_id, :parent_id, :position).first

        this_position = db[@node_type]
                        .filter(:parent_id => this_node[:parent_id])
                        .where { position <= this_node[:position] }
                        .count

        parent_uri = if this_node[:parent_id]
                       JSONModel(@node_type).uri_for(this_node[:parent_id], :repo_id => this_node[:repo_id])
                     else
                       nil
                     end

        result << {:node => parent_uri,
                   :offset => (this_position / WAYPOINT_SIZE.to_f).to_i}

        # No parent ID means we've hit the root
        if this_node[:parent_id]
          ao_id = this_node[:parent_id]
        else
          break
        end
      end
    end

    result.reverse
  end

  def waypoint(parent_id, offset)
    record_ids = []
    records = {}

    DB.open do |db|
      db[@node_table]
        .filter(:root_record_id => @root_record.id,
                :parent_id => parent_id)
        .order(:position)
        .select(:id, :repo_id, :title)
        .offset(offset * WAYPOINT_SIZE)
        .limit(WAYPOINT_SIZE)
        .each do |row|
          record_ids << row[:id]
          records[row[:id]] = row
        end

      # Count up their children
      child_counts = Hash[db[@node_table]
                           .filter(:root_record_id => @root_record.id,
                                   :parent_id => records.keys)
                           .group_and_count(:parent_id)
                           .map {|row| [row[:parent_id], row[:count]]}]

      response = record_ids.map do |id|
        row = records[id]
        child_count = child_counts.fetch(id, 0)

        waypoint_response(child_count).merge("title" => row[:title],
                                             "uri" => JSONModel(@node_type).uri_for(row[:id], :repo_id => row[:repo_id]))

      end

      @decorators.each do |decorator|
        response = decorator.waypoint(response, record_ids)
      end

      response
    end
  end

  private

  # When we return a list of waypoints, the client will pretty much always
  # immediate ask us for the first one in the list.  So, let's have the option
  # of sending them back in the initial response for a given node to save it the
  # extra request.
  def precalculate_waypoints(response, parent_id)
    response['precomputed_waypoints'] = {}

    uri = parent_id ? response['uri'] : ""

    if response['waypoints'] > 0
      response['precomputed_waypoints'][uri] ||= {}
      response['precomputed_waypoints'][uri][0] = waypoint(parent_id, 0)
    end

    response
  end

  def waypoint_response(child_count)
    {
     "child_count" => child_count,
     "waypoints" => (child_count.to_f / WAYPOINT_SIZE).ceil.to_i,
     "waypoint_size" => WAYPOINT_SIZE,
    }
  end

end
