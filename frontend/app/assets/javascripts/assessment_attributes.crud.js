function AssessmentAttributesForm() {
    this.$form = $("#assessment_attributes_form");

    this.setupEvents();
    this.setupDragAndDrop();
};

AssessmentAttributesForm.prototype.setupEvents = function() {
    var self = this;

    self.$form.on('click', '.add-repo-attribute', function(event) {
        event.preventDefault();

        if ($(this).data('type')) {
            var $newRow = AS.renderTemplate('template_' + $(this).data('type'));
            var $tbody = $(this).closest('tbody');
            $tbody.prev('.repository-attributes').append($newRow);
        }
    });

    self.$form.on('click', '.remove-repo-attribute', function(event) {
        event.preventDefault();
        $(this).closest('tr').remove();
    });
};

AssessmentAttributesForm.prototype.setupDragAndDrop = function() {
    var self = this;

    self.$form.find('tbody.repository-attributes').each(function() {
        $(this).sortable({
            handle: '.repo-attribute-drag-handle',
            cursor: "move"
        });
    });
};

$(document).ready(function() {
    new AssessmentAttributesForm();
});