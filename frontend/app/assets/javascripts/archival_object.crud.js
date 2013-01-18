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

			
			
			var $autoTitleChecker = $("#archival_object_title_auto_generate_");
			var $checked = $autoTitleChecker[0].checked;
			
			var $titleInput = $("#archival_object_title_");
			// Lets the title come back if the user toggles in error
			var $userEnteredTitleValue = $titleInput[0].value;
			
			// Disable the title if it's getting auto generated
			var disableTitle = function(){
				$titleInput.prop('disabled', true);
				$titleInput.attr("readonly","readonly");
				$userEnteredTitleValue = $titleInput[0].value;
				$titleInput[0].value = $autoTitleChecker.attr("display_text_when_checked");
			}
			
			if ($checked){
				disableTitle();
			}
			
			$autoTitleChecker.live('change', function() {
				if ($(this).is(':checked')){
					disableTitle();
				} else {
					$titleInput.prop('disabled', false);
					$titleInput.removeAttr("readonly");
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