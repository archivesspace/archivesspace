// Stacked-modal backdrop fix. This seems to be the best solution I could find for the problem.
// Bootstrap assigns all modals z-index:1050 and all backdrops z-index:1040,
// so a second backdrop never dims the modal beneath it.
// Added these two handlers to escalate each new modal and its backdrop above the existing stack.
$(document).on('show.bs.modal', '.modal', function () {
  const openCount = $('.modal.show').length;
  if (openCount > 0) {
    const backdropZ = 1040 + openCount * 20;
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

let accessTopContainersChangesMade = false;

$(document).on('click', '.access-top-containers-btn', function () {
  const $btn = $(this);
  const recordUri = $btn.data('record-uri');
  const recordType = $btn.data('record-type');
  const recordTitle = $btn.data('record-title');

  accessTopContainersChangesMade = false;

  const $modal = AS.openCustomModal(
    'accessTopContainersModal',
    $btn.data('modal-title'),
    `<div class="modal-body"><div class="p-4"><p>${AS.locales.loading}</p></div></div>`,
    'full'
  );

  $modal.one('hidden.bs.modal', function () {
    if (accessTopContainersChangesMade) {
      window.location.reload();
    }
  });

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
  saved = false
) {
  if (saved) {
    accessTopContainersChangesMade = true;
  }
  $.ajax({
    url: AS.app_prefix('top_containers/access_top_containers'),
    data: {
      record_uri: recordUri,
      record_type: recordType,
      record_title: recordTitle,
      saved: saved,
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
  const title =
    mode === 'edit'
      ? AS.access_top_containers_locales.edit_top_container
      : AS.access_top_containers_locales.view_top_container;
  const $subModal = AS.openCustomModal(
    'accessTopContainerSubModal',
    title,
    `<div class="modal-body"><div class="p-4"><p>${AS.locales.loading}</p></div></div>`,
    'large'
  );

  const url = AS.app_prefix(
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
  const parts = uri.split('/');
  return parts[parts.length - 1];
}

$(document).on('click', '.inline-tc-view-btn', function (event) {
  event.preventDefault();
  const id = topContainerIdFromUri($(this).data('tc-uri'));
  if (!id) {
    return;
  }
  openTopContainerSubModal(id, 'view');
});

$(document).on('click', '.inline-tc-edit-btn', function (event) {
  event.preventDefault();
  const id = topContainerIdFromUri($(this).data('tc-uri'));
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

    const $form = $(this);
    const $subModal = $form.closest('#accessTopContainerSubModal');
    const $outerModal = $('#accessTopContainersModal');

    $.ajax({
      url: $form.attr('action'),
      data: $form.serialize() + '&inline=true',
      type: 'POST',
      success: function (response, _ignoredStatus, jqXHR) {
        const contentType = jqXHR.getResponseHeader('Content-Type') || '';

        if (contentType.indexOf('application/json') !== -1) {
          $subModal.modal('hide');

          const recordUri = $outerModal.data('record-uri');
          const recordType = $outerModal.data('record-type');
          const recordTitle = $outerModal.data('record-title');

          $outerModal
            .find('.modal-body')
            .html(`<div class="p-4"><p>${AS.locales.loading}</p></div>`);
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

function reloadAccessTopContainersModal() {
  const $outerModal = $('#accessTopContainersModal');
  const recordUri = $outerModal.data('record-uri');
  const recordType = $outerModal.data('record-type');
  const recordTitle = $outerModal.data('record-title');
  $outerModal
    .find('.modal-body')
    .html(`<div class="p-4"><p>${AS.locales.loading}</p></div>`);
  loadAccessTopContainersModal(
    $outerModal,
    recordUri,
    recordType,
    recordTitle,
    true
  );
}

const bulkActionModalsToClose = {
  batch_merge_form: ['#bulkMergeConfirmModal', '#bulkMergeModal'],
  batch_delete_form: ['#bulkActionModal'],
};

$(document).on(
  'submit',
  '#batch_merge_form, #batch_delete_form',
  function (event) {
    if (!$('#accessTopContainersModal').hasClass('show')) {
      return;
    }
    event.preventDefault();
    const $form = $(this);
    $.ajax({
      url: $form.attr('action'),
      data: $form.serialize() + '&inline=true',
      type: 'POST',
      success: function (_response, _status, jqXHR) {
        const contentType = jqXHR.getResponseHeader('Content-Type') || '';
        if (contentType.indexOf('application/json') !== -1) {
          (bulkActionModalsToClose[$form.attr('id')] || []).forEach(
            function (sel) {
              $(sel).modal('hide');
            }
          );
          reloadAccessTopContainersModal();
        }
      },
      error: function (jqXHR) {
        $form
          .closest('.modal-body')
          .html(
            '<div class="alert alert-danger m-3">' +
              jqXHR.responseText +
              '</div>'
          );
      },
    });
  }
);

$(document).on('loadedrecordform.aspace', function () {
  $('.access-top-containers-btn:not([data-tc-initialized])').each(function () {
    const $btn = $(this);
    $btn.attr('data-tc-initialized', 'true');
    const $wrapper = $btn.closest('.access-top-containers-wrapper');

    $.ajax({
      url: AS.app_prefix('top_containers/access_top_containers'),
      data: {
        record_uri: $btn.data('record-uri'),
        record_type: $btn.data('record-type'),
        count_only: true,
      },
      type: 'GET',
      dataType: 'json',
      success: function (data) {
        $btn.find('.tc-btn-spinner').addClass('d-none');
        $btn.find('.tc-btn-label').removeClass('d-none');

        if (data.count > 0) {
          $btn.prop('disabled', false);
        } else {
          $btn.prop('disabled', true).css('pointer-events', 'none');
          $wrapper
            .attr('data-toggle', 'tooltip')
            .attr('data-placement', 'auto')
            .attr('title', AS.access_top_containers_locales.no_top_containers)
            .addClass('has-tooltip');
          $wrapper
            .tooltip({ container: 'body', placement: 'auto' })
            .addClass('initialised');
        }
      },
      error: function () {
        $btn.find('.tc-btn-spinner').addClass('d-none');
        $btn.find('.tc-btn-label').removeClass('d-none');
        $btn.prop('disabled', false);
      },
    });
  });
});
