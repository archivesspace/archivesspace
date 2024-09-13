get_selection = function () {
  var results = [];

  $(document)
    .find('td.multiselect-column :input:checked')
    .each(function (i, checkbox) {
      results.push({
        uri: checkbox.value,
        display_string: $(checkbox).data('display-string'),
        row: $(checkbox).closest('tr'),
      });
    });

  return results;
};

function activateBtn(event) {
  var merge_btn = $('.merge-button');
  if ($(':input:checked').length > 0) {
    merge_btn.attr('disabled', null);
  } else {
    merge_btn.attr('disabled', 'disabled');
  }
}

$(document).on('click', '#batchMerge', function () {
  let modal_title = 'Merge Container Profiles';
  let dialog_content = AS.renderTemplate('merge_container_profiles_modal', {
    selection: get_selection(),
  });
  AS.openCustomModal('batchMergeModal', modal_title, dialog_content, 'full');

  // Access modal1 DOM
  const $selectTargetBtn = $("[data-js='selectTarget']");

  $selectTargetBtn.on('click', function (e) {
    e.preventDefault();

    console.log('CLICK FROM $SELECTTARGETBTN!');

    // Set up data for form submission
    const mergeList = get_selection().map(function (profile) {
      return {
        uri: profile.uri,
        display_string: profile.display_string,
      };
    });

    const mergeDestinationEl = document.querySelector(
      'input[name="merge_destination[]"]:checked'
    );

    const mergeDestination = {
      display_string: mergeDestinationEl.getAttribute('aria-label'),
      uri: mergeDestinationEl.getAttribute('value'),
    };

    const mergeCandidates = mergeList.reduce(function (acc, profile) {
      if (profile.display_string !== mergeDestination.display_string) {
        acc.push(profile.display_string);
      }
      return acc;
    }, []);

    // Init modal2
    AS.openCustomModal(
      'bulkMergeConfirmModal',
      'Confirm Merge Container Profiles',
      AS.renderTemplate('confirm_merge_container_profiles_modal', {
        mergeList,
        mergeDestination,
        mergeCandidates,
      }),
      false
    );
  });
});
