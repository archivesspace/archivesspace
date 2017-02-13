var TreeIds = {}

/* FIXME: Figure out how to get rid of plural stuff and hopefully all of this... */
TreeIds.uri_to_tree_id = function (uri) {
    var parts = TreeIds.uri_to_parts(uri);
    return parts.type + '_' + parts.id;
}

TreeIds.uri_to_parts = function (uri) {
    var last_part = uri.replace(/\/repositories\/[0-9]+\//,"");
    var bits = last_part.match(/([a-z_]+)\/([0-9]+)/);
    var type_plural = bits[1].replace(/\//g,'_');
    var id = bits[2];
    var type = type_plural.replace(/s$/, '');

    return {
        type: type,
        id: id
    };
}

TreeIds.parse_tree_id = function (tree_id) {
    var regex_match = tree_id.match(/([a-z_]+)([0-9]+)/);
    if (regex_match == null || regex_match.length != 3) {
        return;
    }

    var row_type = regex_match[1].replace(/_$/, "");
    var row_id = regex_match[2];

    return {type: row_type, id: row_id}
}

TreeIds.link_url = function(uri) {
    // convert the uri into tree-speak
    return "#tree::" + TreeIds.uri_to_tree_id(uri);
};

window.TreeIds = TreeIds
