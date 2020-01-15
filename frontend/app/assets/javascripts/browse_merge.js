// fix function def init
function get_selection() {
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



// removed activatBtn function here, because it didn't do anything,
// it was copied from somewhere else (looks like near merge top containers)
// and wasn't actually called; i think the previous author thought
// activateBtn was responsible for the un-disabling of the merge button
// in container profiles view, but it's not, the `$(".multiselect-enabled")`
// bit in frontend/app/assets/javascripts/search.js is what's responsible for it
// this is why i removed that class from the template

$(document).on("click", "#batchMerge", function() {
  let modal_title = "Merge Container Profiles"
  // should be i18n!
  // changed to hardcoded since it's basically hard coded anyways, given
  // that no other markup uses this js
  let dialog_content = AS.renderTemplate("batch_merge_modal_template", {
    selection: get_selection()
  });
  AS.openCustomModal("batchMergeModal", modal_title, dialog_content,
    'full');
});
