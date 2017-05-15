# What's the big idea?
#
# ArchivesSpace has some big trees in it, and sometimes they look a lot like big
# sticks.  Back in the dark ages, we used JSTree for our trees, which in general
# is perfectly cromulent.  We recognized the risk of having some very large
# collections, so dutifully configured JSTree to lazily load subtrees as the
# user expanded them (avoiding having to load the full tree into memory right
# away).
#
# However, time makes fools of us all.  The JSTree approach works fine if your
# tree is fairly well balanced, but that's not what things look like in the real
# world.  Some trees have a single root node and tens of thousands of records
# directly underneath it.  Lazy loading at the subtree level doesn't save you
# here: as soon as you expand that (single) node, you're toast.
#
# This "large tree" business is a way around all of this.  It's effectively a
# hybrid of trees and pagination, except we call the pages "waypoints" for
# reasons known only to me.  So here's the big idea:
#
#  * You want to show a tree.  You ask the API to give you the root node.
#
#  * The root node tells you whether or not it has children, how many children,
#    and how many waypoints that works out to.
#
#  * Each waypoint is a fixed-size page of nodes.  If the waypoint size is set
#    to 200, a node with 1,000 children would have 5 waypoints underneath it.
#
#  * So, to display the records underneath the root node, you fetch the root
#    node, then fetch the first waypoint to get the first N nodes.  If you need
#    to show more nodes (i.e. if the user has scrolled down), you fetch the
#    second waypoint, and so on.
#
#  * The records underneath the root might have their own children, and they'll
#    have their own waypoints that you can fetch in the same way.  It's nodes,
#    waypoints and turtles the whole way down.
#
# All of this interacts with the largetree.js code in the staff and public
# interfaces.  You open a resource record, and largetree.js fetches the root
# node and inserts placeholders for each waypoint underneath it.  As the user
# scrolls towards a placeholder, the code starts building tracks ahead of the
# train, fetching that waypoint and rendering the records it contains.  When a
# user expands a node to view its children, that process repeats again (the node
# is fetched, waypoint placeholders inserted, etc.).
#
# The public interface runs the same code as the staff interface, but with a
# small twist: it fetches its nodes and waypoints from Solr, rather than from
# the live API.  We hit the API endpoints at indexing time and store them as
# Solr documents, effectively precomputing all of the bits of data we need when
# displaying trees.

require 'mixed_content_parser'

class LargeTree

  include JSONModel

  WAYPOINT_SIZE = 200

  def initialize(root_record, opts = {})
    @decorators = []

    @root_record = root_record

    @root_table = @root_type = root_record.class.root_type.intern
    @node_table = @node_type = root_record.class.node_type.intern

    @published_only = opts.fetch(:published_only, false)
  end

  def add_decorator(decorator)
    @decorators << decorator
  end

  def published_filter
    filter = {}

    filter[:publish] = @published_only ? [1] : [0, 1]
    filter[:suppressed] = @published_only ? [0] : [0, 1]

    filter
  end

  def root
    DB.open do |db|
      child_count = db[@node_table]
                    .filter(:root_record_id => @root_record.id,
                            :parent_id => nil)
                    .filter(published_filter)
                    .count

      response = waypoint_response(child_count).merge("title" => @root_record.title,
                                                      "uri" => @root_record.uri,
                                                      "jsonmodel_type" => @root_table.to_s,
                                                      "parsed_title" => MixedContentParser.parse(@root_record.title, '/'))
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
                    .filter(published_filter)
                    .count

      my_position = node_record.position

      node_position = db[@node_table]
                      .filter(:root_record_id => @root_record.id,
                              :parent_id => node_record.parent_id)
                      .filter(published_filter)
                      .where { position < my_position }
                      .count + 1

      response = waypoint_response(child_count).merge("title" => node_record.display_string,
                                                      "uri" => node_record.uri,
                                                      "position" => node_position,
                                                      "jsonmodel_type" => @node_table.to_s)

      @decorators.each do |decorator|
        response = decorator.node(response, node_record)
      end

      precalculate_waypoints(response, node_record.id)

      response
    end
  end

  def node_from_root(node_ids, repo_id)
    child_to_parent_map = {}
    node_to_position_map = {}
    node_to_root_record_map = {}
    node_to_title_map = {}

    result = {}

    DB.open do |db|
      ## Fetch our mappings of nodes to parents and nodes to positions
      nodes_to_expand = node_ids

      while !nodes_to_expand.empty?
        # Get the set of parents of the current level of nodes
        next_nodes_to_expand = []

        db[@node_table]
          .filter(:id => nodes_to_expand)
          .filter(published_filter)
          .select(:id, :parent_id, :root_record_id, :position, :display_string).each do |row|
          child_to_parent_map[row[:id]] = row[:parent_id]
          node_to_position_map[row[:id]] = row[:position]
          node_to_title_map[row[:id]] = row[:display_string]
          node_to_root_record_map[row[:id]] = row[:root_record_id]
          next_nodes_to_expand << row[:parent_id]
        end

        nodes_to_expand = next_nodes_to_expand.compact.uniq
      end

      ## Calculate the waypoint that each node will fall into
      node_to_waypoint_map = {}

      (child_to_parent_map.keys + child_to_parent_map.values).compact.uniq.each do |node_id|
        this_position = db[@node_type]
                        .filter(:parent_id => child_to_parent_map[node_id])
                        .filter(:root_record_id => node_to_root_record_map[node_id])
                        .filter(published_filter)
                        .where { position <= node_to_position_map[node_id] }
                        .count

        node_to_waypoint_map[node_id] = (this_position / WAYPOINT_SIZE)
      end

      root_record_titles = {}
      db[@root_table]
        .join(@node_table, :root_record_id => :id)
        .filter(Sequel.qualify(@node_table, :id) => node_ids)
        .select(Sequel.qualify(@root_table, :id),
                Sequel.qualify(@root_table, :title))
        .distinct
        .each do |row|
        root_record_titles[row[:id]] = row[:title]
      end

      ## Build up the path of waypoints for each node
      node_ids.each do |node_id|
        root_record_id = node_to_root_record_map.fetch(node_id)
        root_record_uri = JSONModel(@root_type).uri_for(root_record_id, :repo_id => repo_id)

        path = []

        current_node = node_id
        while child_to_parent_map[current_node]
          parent_node = child_to_parent_map[current_node]

          path << {"node" => JSONModel(@node_type).uri_for(parent_node, :repo_id => repo_id),
                   "root_record_uri" => root_record_uri,
                   "jsonmodel_type" => @node_type,
                   "title" => node_to_title_map.fetch(parent_node),
                   "offset" => node_to_waypoint_map.fetch(current_node),
                   "parsed_title" => MixedContentParser.parse(node_to_title_map.fetch(parent_node), '/')}

          current_node = parent_node
        end

        path << {"node" => nil,
                 "root_record_uri" => root_record_uri,
                 "offset" => node_to_waypoint_map.fetch(current_node),
                 "jsonmodel_type" => @root_type,
                 "title" => root_record_titles[root_record_id],
                 "parsed_title" => MixedContentParser.parse(root_record_titles[root_record_id], '/')}

        result[node_id] = path.reverse
      end
    end

    result
  end


  def waypoint(parent_id, offset)
    record_ids = []
    records = {}

    DB.open do |db|
      db[@node_table]
        .filter(:root_record_id => @root_record.id,
                :parent_id => parent_id)
        .filter(published_filter)
        .order(:position)
        .select(:id, :repo_id, :title, :position)
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
                           .filter(published_filter)
                           .group_and_count(:parent_id)
                           .map {|row| [row[:parent_id], row[:count]]}]

      response = record_ids.each_with_index.map do |id, idx|
        row = records[id]
        child_count = child_counts.fetch(id, 0)

        waypoint_response(child_count).merge("title" => row[:title],
                                             "parsed_title" => MixedContentParser.parse(row[:title], '/'),
                                             "uri" => JSONModel(@node_type).uri_for(row[:id], :repo_id => row[:repo_id]),
                                             "position" => (offset * WAYPOINT_SIZE) + idx,
                                             "parent_id" => parent_id,
                                             "jsonmodel_type" => @node_type.to_s)

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
