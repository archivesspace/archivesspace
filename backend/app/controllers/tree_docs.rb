# Putting some documentation in constants here because the same descriptions
# apply to all tree types.

class TreeDocs

  ROOT_DOCS = <<EOS.strip
Returns a JSON object describing enough information about this tree's root record to render the rest.  Includes:

  * title -- the collection title

  * uri -- the collection URI

  * child_count -- the number of immediate children

  * waypoints -- the number of "waypoints" those children are grouped into

  * waypoint_size -- the number of children in each waypoint
EOS

WAYPOINT_DOCS = <<EOS.strip
Returns a JSON array containing information for the records contained in a given waypoint.  Each array element is an object that includes:

  * title -- the record's title

  * uri -- the record URI

  * position -- the logical position of this record within its subtree

  * parent_id -- the internal ID of this document's parent
EOS

NODE_DOCS = <<EOS.strip
Returns a JSON object describing enough information about a specific node.  Includes:

  * title -- the collection title

  * uri -- the collection URI

  * child_count -- the number of immediate children

  * waypoints -- the number of "waypoints" those children are grouped into

  * waypoint_size -- the number of children in each waypoint

  * position -- the logical position of this record within its subtree

  * precomputed_waypoints -- a collection of arrays (keyed on child URI) in the
    same format as returned by the '/waypoint' endpoint.  Since a fetch for a
    given node is almost always followed by a fetch of the first waypoint, using
    the information in this structure can save a backend call.
EOS

NODE_FROM_ROOT_DOCS = <<EOS.strip
Returns a JSON array describing the path to a node, starting from the root of the tree.  Each path element provides:

  * node -- the URI of the node to next expand

  * offset -- the waypoint number within `node` that contains the next entry in
    the path (or the desired record, if we're at the end of the path)
EOS

end
