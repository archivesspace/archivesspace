//= require slug
//= require lang_materials.crud
//= require bulk_import
//= require clipboard

$(function() {
    $.fn.init_archival_object_form = function() {
        $(this).each(function() {
            var $this = $(this);

            if ($this.hasClass("initialised")) {
                return;
            };

            var $levelSelect = $("#archival_object_level_", $this);
            var $otherLevel = $("#archival_object_other_level_", $this);

            var handleLevelChange = function(initialising) {
                if ($levelSelect.val() === "otherlevel") {
                    $otherLevel.removeAttr("disabled");
                    if (initialising === true) {
                        $otherLevel.closest(".form-group").show();
                    } else {
                        $otherLevel.closest(".form-group").slideDown();
                    }
                } else {
                    $otherLevel.attr("disabled", "disabled");
                    if (initialising === true) {
                        $otherLevel.closest(".form-group").hide();
                    } else {
                        $otherLevel.closest(".form-group").slideUp();
                    }
                }
            };

            handleLevelChange(true);
            $levelSelect.change(handleLevelChange);
        });
    };

    $(document).bind("loadedrecordform.aspace", function(event, $container) {
        $("#archival_object_form:not(.initialised)", $container).init_archival_object_form();
    });

    $("#archival_object_form:not(.initialised)").init_archival_object_form();

});