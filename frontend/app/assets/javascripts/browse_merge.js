get_selection = function() {
  var results = [];

  $(document).find(".multiselect-column :input:checked").each(function(i, checkbox) {
    results.push({
      uri: checkbox.value,
      display_string: $(checkbox).data("display-string"),
      row: $(checkbox).closest("tr")
    });
  });

  return results;
};

function activateBtn(event) {
  var merge_btn = document.getElementsByClassName("merge-button")[0];
  if ($(":input:checked").length > 0) {
    merge_btn.removeAttribute("disabled");
  } else {
    merge_btn.attr("disabled", "disabled");
  };
};

$(document).on("click", "#batchMerge", function() {
  let modal_title = "Merge Container Profiles";
  let dialog_content = AS.renderTemplate("merge_container_profiles_modal", {
    selection: get_selection()
  });
  AS.openCustomModal("batchMergeModal", modal_title, dialog_content,
    'full');
});
