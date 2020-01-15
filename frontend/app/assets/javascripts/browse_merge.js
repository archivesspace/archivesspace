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

function activateBtn(event) {
  var merge_btn = document.getElementsByClassName("merge-button")[0];
  if ($(":input:checked").length > 0) {
    merge_btn.removeAttribute("disabled");
  } else {
    merge_btn.attr("disabled", "disabled");
  };
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
  // that no other markup uses this js;
  // should be made dynamically in the future, and should leverage i18n
  
  let dialog_content = AS.renderTemplate("merge_container_profiles_modal", {
    selection: get_selection()
  });
  
  AS.openCustomModal("batchMergeModal", modal_title, dialog_content,
    'full');
  
  // Access modal1 DOM
  const $selectTargetBtn = $("[data-js='selectTarget']");
    
  $selectTargetBtn.on("click", function(e) {
    e.preventDefault();

    // Set up data for form submission
    const mergeList = get_selection()
                      .map(function(profile) {
                        return {
                          uri: profile.uri,
                          display_string: profile.display_string
                        }
                      });

    const targetEl = document.querySelector('input[name="target[]"]:checked');

    const target = {
      display_string: targetEl.getAttribute('aria-label'),
      uri: targetEl.getAttribute('value')
    };
    
    // compute victims list for template rendering
    const victims = mergeList.reduce(function(acc, profile) {
      if (profile.display_string !== target.display_string) {
        acc.push(profile.display_string);
      }
      return acc;
    }, [])
    
    // Init modal2
    AS.openCustomModal("bulkMergeConfirmModal", "Confirm Merge Container Profiles", AS.renderTemplate("merge_confirm_container_profiles_modal", {
      mergeList,
      target,
      victims
    }), false);
  });

});
