TreeIds.link_url = function(uri) {
    /* For the public interface we'll just straight up link to the URL. */
    return uri;
};

function BaseRenderer() {
    this.endpointMarkerTemplate = $('<tr class="end-marker" />');

    this.rootTemplate = $('<tr> ' +
                          '  <td class="no-drag-handle"></td>' +
                          '  <td class="title"></td>' +
                          '</tr>');


    this.nodeTemplate = $('<tr> ' +
                          '  <td class="drag-handle"></td>' +
                          '  <td class="title"><span class="indentor"><button class="expandme"><i class="expandme-icon icon-chevron-right" /></button></span> </td>' +
                          '</tr>');
}

BaseRenderer.prototype.endpoint_marker = function () {
    return this.endpointMarkerTemplate.clone(true);
}

BaseRenderer.prototype.get_root_template = function () {
    return this.rootTemplate.clone(false);
}


BaseRenderer.prototype.get_node_template = function () {
    return this.nodeTemplate.clone(false);
};

function ResourceRenderer() {
    BaseRenderer.call(this);
    this.rootTemplate = $('<tr> ' +
                          '  <td class="no-drag-handle"></td>' +
                          '  <td class="title"></td>' +
                          '  <td class="resource-level"></td>' +
                          '  <td class="resource-type"></td>' +
                          '  <td class="resource-container"></td>' +
                          '</tr>');

    this.nodeTemplate = $('<tr> ' +
                          '  <td class="drag-handle"></td>' +
                          '  <td class="title"><span class="indentor"><button class="expandme"><i class="expandme-icon icon-chevron-right" /></button></span> </td>' +
                          '  <td class="resource-level"></td>' +
                          '  <td class="resource-type"></td>' +
                          '  <td class="resource-container"></td>' +
                          '</tr>');
}

ResourceRenderer.prototype = Object.create(BaseRenderer.prototype);

ResourceRenderer.prototype.add_root_columns = function (row, rootNode) {
    row.find('.resource-level').text(rootNode.level).attr('title', rootNode.level);
    row.find('.resource-type').text(rootNode.type).attr('title', rootNode.type);
    row.find('.resource-container').text(rootNode.container).attr('title', rootNode.container);
}


ResourceRenderer.prototype.add_node_columns = function (row, node) {
    row.find('.resource-level').text(node.level).attr('title', node.level);
    row.find('.resource-type').text(node.type).attr('title', node.type);
    row.find('.resource-container').text(node.container).attr('title', node.container);
};
