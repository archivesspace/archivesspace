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
            $otherLevel.closest(".control-group").show();
          } else {
            $otherLevel.closest(".control-group").slideDown();
          }
        } else {
          $otherLevel.attr("disabled", "disabled");
          if (initialising === true) {
            $otherLevel.closest(".control-group").hide();
          } else {
            $otherLevel.closest(".control-group").slideUp();
          }
        }
      };

      handleLevelChange(true);
      $levelSelect.change(handleLevelChange);

			
			
			var $autoTitleChecker = $("#archival_object_title_automatic_");
			var $checked = $autoTitleChecker[0].checked;
			
			var $titleInput = $("#archival_object_title_");
			// Let's the title come back if the user toggles in error
			var $userEnteredTitleValue = $titleInput[0].value;
			
			$autoTitleChecker.live('change', function() {
				if ($(this).is(':checked')){

					$titleInput.prop('disabled', true);
					$userEnteredTitleValue = $titleInput[0].value;
					$titleInput[0].value = "Automatic for the people";
					$titleInput.attr("readonly","readonly");
					
				} else {
					$titleInput.prop('disabled', false);
					$titleInput[0].value = $userEnteredTitleValue;
				}
			});


    });
  };

  $(document).ajaxComplete(function() {
    $("#archival_object_form:not(.initialised)").init_archival_object_form();
  });

  $("#archival_object_form:not(.initialised)").init_archival_object_form();

});