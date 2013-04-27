//= require subrecord.crud
//= require notes.crud
//= require related_agents.crud

$(function() {

  var init_name_form = function(subform) {
    var $checkbox = $(":checkbox[name$=\"[sort_name_auto_generate]\"]", subform);
    var $sortNameField = $(":input[name$=\"[sort_name]\"]", subform);

		var disableSortName = function() {
			$sortNameField.attr("readonly","readonly");
			$sortNameField.prop('disabled', true);
			$sortNameField.attr("readonly","readonly");
			$userEnteredSortNameValue = $sortNameField[0].value;
			$sortNameField[0].value = $checkbox.attr("display_text_when_checked");
		}


    if ($checkbox.is(":checked")) {
      disableSortName();
      // $sortNameField.closest(".control-group").hide();
    }

    $checkbox.change(function() {
      if ($checkbox.is(":checked")) {
				disableSortName();
        // $sortNameField.attr("readonly","readonly");
        // $sortNameField.closest(".control-group").hide();
      } else {
				$sortNameField.prop('disabled', false);
        $sortNameField.removeAttr("readonly");
				$sortNameField[0].value = $userEnteredSortNameValue;
        // $sortNameField.closest(".control-group").show();
      }
    });
  };

	


  $(document).bind("subrecordcreated.aspace", function(event, object_name, subform) {
    if (object_name === "name") {
      init_name_form($(subform));
    }
  });

});
