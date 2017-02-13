function BaseRenderer() {
    this.endpointMarkerTemplate = $('<tr class="waypoint end-marker" />');

    this.rootTemplate = $('<tr> ' +
                          '  <td class="no-drag-handle"></td>' +
                          '  <td class="title"></td>' +
                          '</tr>');


    this.nodeTemplate = $('<tr> ' +
                          '  <td class="drag-handle"></td>' +
                          '  <td class="title"><span class="indentor"><button class="expandme"><i class="expandme-icon glyphicon glyphicon-chevron-right" /></button></span> </td>' +
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
                          '  <td class="title"><span class="indentor"><button class="expandme"><i class="expandme-icon glyphicon glyphicon-chevron-right" /></button></span> </td>' +
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


function DigitalObjectRenderer() {
    BaseRenderer.call(this);


    this.rootTemplate = $('<tr> ' +
                          '  <td class="no-drag-handle"></td>' +
                          '  <td class="title"></td>' +
                          '  <td class="digital-object-type"></td>' +
                          '  <td class="file-uri-summary"></td>' +
                          '</tr>');


    this.nodeTemplate = $('<tr> ' +
                          '  <td class="drag-handle"></td>' +
                          '  <td class="title"><span class="indentor"><button class="expandme"><i class="expandme-icon glyphicon glyphicon-chevron-right" /></button></span> </td>' +
                          '  <td class="digital-object-type"></td>' +
                          '  <td class="file-uri-summary"></td>' +
                          '</tr>');
}

DigitalObjectRenderer.prototype = BaseRenderer.prototype;

DigitalObjectRenderer.prototype.add_root_columns = function (row, rootNode) {
    if (rootNode.digital_object_type) {
        row.find('.digital-object-type').text(rootNode.digital_object_type).attr('title', rootNode.digital_object_type);
    }

    if (rootNode.file_uri_summary) {
        row.find('.file-uri-summary').text(rootNode.file_uri_summary).attr('title', rootNode.file_uri_summary);
    }
}

DigitalObjectRenderer.prototype.add_node_columns = function (row, node) {
    row.find('.file-uri-summary').text(node.file_uri_summary).attr('title', node.file_uri_summary);
};

function ClassificationRenderer() {
    BaseRenderer.call(this);
}

ClassificationRenderer.prototype = BaseRenderer.prototype;
