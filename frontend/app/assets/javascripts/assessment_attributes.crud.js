function AssessmentAttributesForm() {
    this.$form = $("#assessment_attributes_form");

    this.setupEvents();
};

AssessmentAttributesForm.prototype.setupEvents = function() {
    var self = this;

    self.$form.on('click', '.add-repo-attribute', function(event) {
        event.preventDefault();

        if ($(this).data('type')) {
            var $newRow = AS.renderTemplate('template_' + $(this).data('type'));
            $(this).closest('tr').before($newRow);
        }
    });

    self.$form.on('click', '.remove-repo-attribute', function(event) {
        event.preventDefault();
        $(this).closest('tr').remove();
    });
};

$(document).ready(function() {
    new AssessmentAttributesForm();
});