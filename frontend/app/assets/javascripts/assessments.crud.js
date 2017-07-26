//= require subrecord.crud
//= require form

function AssessmentsForm($form) {
    this.$form = $form;

    this.$form.find(".linker:not(.initialised)").linker();
    this.setupRatingTable();
    this.setupCheckboxes();
};



AssessmentsForm.prototype.setupRatingTable = function() {
    var self = this;
    var $table = self.$form.find('#rating_attributes_table');

    self.setupRatingNotes($table);

    $table.on('click', 'td', function(event) {
        if ($(this).find(':radio').length > 0) {
            var $radio = $(this).find(':radio');

            if ($radio.is(':not(:checked)')) {
                $radio.prop('checked', true);
            }
        }

        return true;
    });
};


AssessmentsForm.prototype.setupRatingNotes = function($table) {
    var self = this;

    $table.on('click', '.assessment-add-rating-note', function(event) {
        event.preventDefault();

        var $ratingRow = $(this).closest('tr');

        var $noteRow = $ratingRow.next();
        $noteRow.find('textarea').prop('disabled', false);

        $noteRow.show();

        $(this).hide();
        $(this).siblings('.assessment-remove-rating-note').show();
    });

    $table.on('click', '.assessment-remove-rating-note', function(event) {
        event.preventDefault();

        var $ratingRow = $(this).closest('tr');

        var $noteRow = $ratingRow.next();
        $noteRow.find('textarea').prop('disabled', true);

        $noteRow.hide();

        $(this).hide();
        $(this).siblings('.assessment-add-rating-note').show();
    });

    $table.find('textarea[id$="_note_"]').each(function() {
        var $textarea = $(this);
        if ($textarea.val() == "") {
            $textarea.prop('disabled', true);
        } else {
            var $ratingNoteRow = $textarea.closest('tr');
            var $ratingRow = $ratingNoteRow.prev();

            $ratingNoteRow.show();

            $ratingRow.find('.assessment-add-rating-note').hide();
            $ratingRow.find('.assessment-remove-rating-note').show();
        }
    });
};


AssessmentsForm.prototype.setupCheckboxes = function() {
    var self = this;

    var $tables = self.$form.find('#format_attributes, #conservation_issue_attributes');

    $tables.on('click', ':checkbox', function(event) {
        if ($(this).is(':checked')) {
            $(this).closest('.form-group').find(':hidden').prop('disabled', false);
        } else {
            $(this).closest('.form-group').find(':hidden').prop('disabled', true);
        }

        return true;
    });
};


$(document).ready(function() {
    new AssessmentsForm($('form#assessment_form'));
});