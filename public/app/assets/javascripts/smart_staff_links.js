$(function () {
  if (
    typeof RECORD_URI === 'undefined' ||
    typeof FRONTEND_URL === 'undefined'
  ) {
    return;
  }

  if ($('#staff-link').length == 0) {
    return;
  }

  $.ajax(FRONTEND_URL + '/check_session', {
    data: {
      uri: RECORD_URI,
    },
    type: 'GET',
    dataType: 'json',
    xhrFields: {
      withCredentials: true,
    },
  })
    .done(function (data) {
      if (data === true) {
        var staff = $('#staff-link');
        const link = `${FRONTEND_URL}/resolve/${STAFF_LINK_MODE}?uri=${RECORD_URI}&autoselect_repo=true`;
        staff.attr('href', link);
        staff.removeClass('d-none');

        // staff-hidden aka hidden from non-staff users
        var staff_hidden = $('.staff-hidden');
        staff_hidden.removeClass('d-none');
      }
    })
    .fail(function () {
      // do nothing
    });
});
