# Putting some documentation in constants here because the same descriptions
# apply to all tree types.

class TreeDocs

  ROOT_DOCS = <<~EOS.strip
    Returns a JSON object describing enough information about this tree's root record to render the rest.  Includes:

      * child_count (Integer) -- Number of immediate children of the root record

      * waypoints (Integer) -- Number of "waypoints" those children are grouped into. The first waypoint is precomputed and included in the response (see precomputed_wayoints below). Additional waypoints can be retireved via `/repositories/:repo_id/:record_type/:id/tree/waypoint`

      * waypoint_size (Integer) -- The limit to the number of children included in each waypoint

      * title (String) -- Record title

      * uri (String) -- Record URI

      * precomputed_waypoints (JSON) -- A nested JSON object containing the first "waypoint" (set of children), limited to `waypoint_size`. The JSON object is structured as follows: `{ "": { "0": [<JSON Object>] }`.  `precomputed_waypoints[''][0]` is an array of JSON objects representing immediate children of the root record. The format of this object is similar to the object returned by: `/repositories/:repo_id/:record_type/:id/tree/node` but without its own precomputed_waypoints.

      **Resource records** only:

      * level (String) -- Level of arrangement (e.g. collection)

      **Resource and Classification records** only:

      * identifier (String) -- The root record identifier

      **Digital Object records** only:

      * digital_object_type (String) -- Type of the digital object (e.g. still_image)

      * file_uri_summary (String) -- The file uri of the root digital object

  EOS

  WAYPOINT_DOCS = <<~EOS.strip
    Returns a JSON array containing information for the records contained in a given waypoint.  Each array element is an object that includes:
    
      * title -- the record's title
    
      * uri -- the record URI
    
      * position -- the logical position of this record within its subtree
    
      * parent_id -- the internal ID of this document's parent
    EOS

  NODE_DOCS = <<~EOS.strip
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

  NODE_FROM_ROOT_DOCS = <<~EOS.strip
    Returns a JSON array describing the path to a node, starting from the root of the tree.  Each path element provides:
    
      * node -- the URI of the node to next expand
    
      * offset -- the waypoint number within `node` that contains the next entry in
        the path (or the desired record, if we're at the end of the path)
    EOS

end
