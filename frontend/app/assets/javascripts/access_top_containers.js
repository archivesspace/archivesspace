// Stacked-modal backdrop fix. This seems to be the best solution I could find for the problem.
// Bootstrap assigns all modals z-index:1050 and all backdrops z-index:1040,
// so a second backdrop never dims the modal beneath it.
// I added these twohandlers to escalate each new modal and its backdrop above the existing stack.
$(document).on('show.bs.modal', '.modal', function () {
  var openCount = $('.modal.show').length;
  if (openCount > 0) {
    var backdropZ = 1040 + openCount * 20;
    $(this).css('z-index', backdropZ + 10);
    setTimeout(function () {
      $('.modal-backdrop').last().css('z-index', backdropZ);
    }, 0);
  }
});

$(document).on('hidden.bs.modal', '.modal', function () {
  if ($('.modal.show').length > 0) {
    $('body').addClass('modal-open');
  }
});

$(document).on('click', '.access-top-containers-btn', function () {
  var $btn = $(this);
  var recordUri = $btn.data('record-uri');
  var recordType = $btn.data('record-type');
  var recordTitle = $btn.data('record-title');

  var $modal = AS.openCustomModal(
    'accessTopContainersModal',
    recordTitle,
    '<div class="modal-body"><div class="p-4"><p>Loading...</p></div></div>',
    'full'
  );

  $modal.data('record-uri', recordUri);
  $modal.data('record-type', recordType);
  $modal.data('record-title', recordTitle);

  loadAccessTopContainersModal($modal, recordUri, recordType, recordTitle);
});

function loadAccessTopContainersModal(
  $modal,
  recordUri,
  recordType,
  recordTitle,
  saved
) {
  $.ajax({
    url: AS.app_prefix('top_containers/access_top_containers'),
    data: {
      record_uri: recordUri,
      record_type: recordType,
      record_title: recordTitle,
      saved: saved || false,
    },
    type: 'GET',
    success: function (html) {
      $modal.find('.modal-body').html(html);
      $('.linker:not(.initialised)', $modal).linker();
      AS.initBulkContainerOperations(
        null,
        $modal.find('#bulk_operation_results'),
        $modal.find('.record-toolbar.bulk-operation-toolbar')
      );
    },
    error: function (jqXHR) {
      $modal
        .find('.modal-body')
        .html(
          '<div class="alert alert-danger m-3">' + jqXHR.responseText + '</div>'
        );
    },
  });
}

function openTopContainerSubModal(tcId, mode) {
  var title = mode === 'edit' ? 'Edit Top Container' : 'Top Container';
  var $subModal = AS.openCustomModal(
    'accessTopContainerSubModal',
    title,
    '<div class="modal-body"><div class="p-4"><p>Loading...</p></div></div>',
    'large'
  );

  var url = AS.app_prefix(
    'top_containers/' + tcId + (mode === 'edit' ? '/edit' : '')
  );

  $.ajax({
    url: url,
    data: { inline: true },
    type: 'GET',
    success: function (html) {
      $subModal.find('.modal-body').html(html);
      if (mode === 'edit') {
        $('.linker:not(.initialised)', $subModal).linker();
        $(document).trigger('loadedrecordform.aspace', [
          $subModal.find('.modal-body'),
        ]);
      }
    },
    error: function (jqXHR) {
      $subModal
        .find('.modal-body')
        .html(
          '<div class="alert alert-danger m-3">' + jqXHR.responseText + '</div>'
        );
    },
  });

  return $subModal;
}

function topContainerIdFromUri(uri) {
  if (!uri) {
    return null;
  }
  var parts = uri.split('/');
  return parts[parts.length - 1];
}

$(document).on('click', '.inline-tc-view-btn', function (event) {
  event.preventDefault();
  var id = topContainerIdFromUri($(this).data('tc-uri'));
  if (!id) {
    return;
  }
  openTopContainerSubModal(id, 'view');
});

$(document).on('click', '.inline-tc-edit-btn', function (event) {
  event.preventDefault();
  var id = topContainerIdFromUri($(this).data('tc-uri'));
  if (!id) {
    return;
  }
  openTopContainerSubModal(id, 'edit');
});

$(document).on(
  'submit',
  '#accessTopContainerSubModal form.aspace-record-form',
  function (event) {
    event.preventDefault();

    var $form = $(this);
    var $subModal = $form.closest('#accessTopContainerSubModal');
    var $outerModal = $('#accessTopContainersModal');

    $.ajax({
      url: $form.attr('action'),
      data: $form.serialize() + '&inline=true',
      type: 'POST',
      success: function (response, _ignoredStatus, jqXHR) {
        var contentType = jqXHR.getResponseHeader('Content-Type') || '';

        if (contentType.indexOf('application/json') !== -1) {
          $subModal.modal('hide');

          var recordUri = $outerModal.data('record-uri');
          var recordType = $outerModal.data('record-type');
          var recordTitle = $outerModal.data('record-title');

          $outerModal
            .find('.modal-body')
            .html('<div class="p-4"><p>Loading...</p></div>');
          loadAccessTopContainersModal(
            $outerModal,
            recordUri,
            recordType,
            recordTitle,
            true
          );
        } else {
          $subModal.find('.modal-body').html(response);
          $('.linker:not(.initialised)', $subModal).linker();
          $(document).trigger('loadedrecordform.aspace', [
            $subModal.find('.modal-body'),
          ]);
        }
      },
      error: function (jqXHR) {
        $subModal
          .find('.modal-body')
          .html(
            '<div class="alert alert-danger m-3">' +
              jqXHR.responseText +
              '</div>'
          );
      },
    });
  }
);
