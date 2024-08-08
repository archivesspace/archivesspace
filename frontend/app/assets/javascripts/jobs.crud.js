//= require form

var init = function () {
  var $form = $('#job_form');

  var initReportJobForm = function () {
    var locationReportSubFormChange = function () {
      var selected_report_type = $(
        '#job_job_params_location_report_type_'
      ).val();

      var location_start_linker = $('#report_location_start');
      var location_end_linker = $('#report_location_end');

      if (selected_report_type === 'single_location') {
        location_end_linker.hide();
        location_start_linker
          .find('label')
          .text(location_start_linker.data('singular-label'));
      } else if (selected_report_type === 'location_range') {
        location_start_linker
          .find('label')
          .text(location_start_linker.data('range-label'));
        location_end_linker
          .find('label')
          .text(location_end_linker.data('range-label'));
        location_end_linker.show();
      }

      $('.report_type').hide();
      $('.report_type.' + selected_report_type).show();
    };

    $(document).on(
      'change',
      '#job_job_params_location_report_type_',
      locationReportSubFormChange
    );

    var formatChange = function () {
      if ($('#job_format_').val() == 'csv') {
        $('.csv_options').show();
      } else {
        $('.csv_options').hide();
      }
    };

    formatChange();
    $(document).on('change', '#job_format_', formatChange);

    var initListing = function (report) {
      $('#report-fields').html(
        AS.renderTemplate('template_' + report, {
          id_path: 'job_job_params',
          path: 'job[job_params]',
        })
      );
      if (report == 'location_holdings_report') {
        locationReportSubFormChange();
      }
      $(document).triggerHandler('subrecordcreated.aspace', [
        report,
        $('#report-fields'),
      ]);
    };

    $('.unselect-report').hide();
    $('.create-report-template').hide();
    $('#format').hide();
    $('.btn-primary:submit').addClass('disabled');

    $('.select-report, .report-title').click(function () {
      var code = $(this).attr('for');
      $('#job_report_type_').val(code);
      initListing(code);
      $('.select-report').hide();
      $('.unselect-report').show();
      $('.unselect-report-group').addClass('ml-auto');
      $('.create-report-template').show();
      $('.report-listing:not(#' + code + ')').hide();
      $('#format').show();
      $('.btn-primary:submit').removeClass('disabled');
      $('.report-title').addClass('disabled');
      $('.report-title').blur();
      $('#archivesSpaceSidebar li').toggle();
    });

    $('.unselect-report').click(function () {
      $('#job_report_type_').val(null);
      $('#report-fields').empty();
      $('.select-report').show();
      $('.unselect-report').hide();
      $('.unselect-report-group').removeClass('ml-auto');
      $('.create-report-template').hide();
      $('.report-listing').show();
      $('#format').hide();
      $('.btn-primary:submit').addClass('disabled');
      $('.report-title').removeClass('disabled');
      // we're going back, remove any extra params
      window.history.replaceState(
        null,
        null,
        window.location.pathname + '?job_type=report_job'
      );
    });

    // select a report if params are available
    const urlParams = new URLSearchParams(window.location.search);
    const reportType = urlParams.get('report_type');

    if (reportType) {
      $('#' + reportType + ' .select-report').click();

      // lets try all of our params to see if there's a matching form element
      urlParams.forEach(function (value, key) {
        var paramSelector = '#job_job_params_' + key + '_';

        // move along if there's no matching form element for this param
        if (!$(paramSelector).length) {
          return true;
        }

        var tag = $(paramSelector).get(0).tagName;
        switch (tag) {
          case 'INPUT':
            var type = $(paramSelector).get(0).type;
            if (type == 'checkbox') {
              $(paramSelector).prop('checked', Boolean(parseInt(value)));
            } else {
              $(paramSelector).val(value);
            }
            break;
          case 'SELECT':
            paramSelector = paramSelector + ' option';
            $(paramSelector)
              .filter(function (i, e) {
                return $(e).text() == value;
              })
              .prop('selected', true);
            break;
          default:
            console.log('Unhandled [key, value, tag]', key, value, tag);
        }
      });
    }
  };

  var initSourceJobForm = function () {
    $('#job_ref_').attr('name', 'job[source]').attr('id', 'job_source_');
  };

  var initFindAndReplaceJobForm = function () {
    $('#job_form_messages', $form).html(
      AS.renderTemplate('template_find_and_replace_warning')
    );

    // init findAndReplaceForm
    var $selectRecordType = $('#job_record_type_');
    var $selectProperty = $('#job_property_');

    $selectRecordType.attr('disabled', 'disabled');
    $selectProperty.attr('disabled', 'disabled');

    $('#job_ref_').attr('name', 'job[base_record_uri]');

    $('#job_ref_').change(function () {
      var recordUri = $(this).val();
      if (recordUri.length) {
        var id = /\d+$/.exec(recordUri)[0];
        var archivalLevel = recordUri.includes('resource')
          ? 'resources'
          : 'archival_objects';
        $.ajax({
          url: AS.app_prefix(
            '/' + archivalLevel + '/' + id + '/models_in_graph'
          ),
          success: function (typeList) {
            var oldVal = $selectRecordType.val();
            $selectRecordType.empty();
            $selectRecordType.append(
              $('<option>', {
                selected: true,
                disabled: true,
              }).text(' -- select a record type --')
            );
            $.each(typeList, function (index, valAndText) {
              var opts = {
                value: valAndText[0],
              };
              if (oldVal === valAndText[0]) opts.selected = true;

              $selectRecordType.append($('<option>', opts).text(valAndText[1]));
            });
            $selectRecordType.attr('disabled', null);
            if (oldVal != $selectRecordType.val())
              $selectRecordType.triggerHandler('change');
          },
        });
      }
    });

    $selectRecordType.change(function () {
      var recordType = $(this).val();
      $.ajax({
        url: AS.app_prefix(
          '/schema/' + recordType + '/properties?type=string&editable=true'
        ),
        success: function (propertyList) {
          $selectProperty.empty();

          $.each(propertyList, function (index, valAndText) {
            $selectProperty.append(
              $('<option>', {
                value: valAndText[0],
              }).text(valAndText[1])
            );
          });

          $selectProperty.attr('disabled', null);
        },
      });
    });
  };

  var initImportJobForm = function () {
    var supportsHTML5MultipleFileInput = function () {
      var input = document.createElement('input');
      input.setAttribute('multiple', 'true');
      return input.multiple === true;
    };

    var initFileUploadSection = function () {
      var $dropContainer = $('#files');

      var handleFileInputChange = function () {
        $('.hint', $dropContainer).remove();

        var $input = $(this);

        // if browser supports multiple files, then iterate through each
        // and add them to the list
        if (supportsHTML5MultipleFileInput()) {
          $(this.files).each(function (idx, file) {
            var filename = file.name.split('\\').reverse()[0];
            var $file_html = $(
              AS.renderTemplate('template_import_file', {
                filename: filename,
              })
            );

            $file_html.data('file', file);
            $file_html.addClass('file-attached');

            $input.val('');

            $dropContainer.append($file_html);
          });

          // Otherwise, there's only one file, so create an cloned input for it
          // This is for older browsers (like IE8) that don't support the new
          // HTML5 input#file mulitple feature
        } else {
          var filename = $input.val().split('\\').reverse()[0];
          var $file_html = $(
            AS.renderTemplate('template_import_file', {
              filename: filename,
            })
          );

          $file_html.append($input);
          var $clone = $input.clone();
          $clone.on('change', handleFileInputChange);
          $('.fileinput-button', $form).append($clone);

          $dropContainer.append($file_html);
        }
      };

      $(':file', $form).on('change', handleFileInputChange);

      $dropContainer.on('click', '.btn-remove-file', function () {
        $(this).closest('.import-file').remove();
      });

      $dropContainer
        .on('dragenter', function (e) {
          e.stopPropagation();
          e.preventDefault();
          $(this).addClass('active');
        })
        .on('dragover', function (e) {
          e.stopPropagation();
          e.preventDefault();
        })
        .on('dragleave', function (e) {
          e.stopPropagation();
          e.preventDefault();

          $(this).removeClass('active');
        })
        .on('drop', function (event) {
          $(this).removeClass('incoming').removeClass('active');

          $.each(event.originalEvent.dataTransfer.files, function (i, file) {
            var $file_html = $(
              AS.renderTemplate('template_import_file', {
                filename: file.name,
              })
            );
            $file_html.data('file', file);
            $file_html.addClass('file-attached');

            $dropContainer.append($file_html);
          });
        });

      // Only allow drop into the #files container
      $(document)
        .on('dragenter', function (e) {
          e.stopPropagation();
          e.preventDefault();

          $dropContainer.addClass('incoming');
        })
        .on('dragover', function (e) {
          e.stopPropagation();
          e.preventDefault();

          $dropContainer.addClass('incoming');
        })
        .on('dragleave', function (e) {
          e.stopPropagation();
          e.preventDefault();

          $dropContainer.removeClass('incoming');
        })
        .on('drop', function (e) {
          e.stopPropagation();
          e.preventDefault();

          $dropContainer.removeClass('incoming').removeClass('active');
        });
    };

    var onChange = function () {
      $('#job_filenames_', $form)
        .empty()
        .append(AS.renderTemplate('template_fileupload'))
        .slideDown();

      initFileUploadSection();
    };

    $('#job_import_type_', $form).change(onChange);

    onChange();

    var handleError = function (errorHTML) {
      $('body').html(errorHTML);
      $(init);
    };

    $form.submit(function () {
      $('.import-file.file-attached').each(function () {
        var dt = new DataTransfer();
        dt.items.add($(this).data('file'));

        const input = document.createElement('input');
        input.type = 'file';
        input.name = 'files[]';
        input.style.display = 'none';
        input.files = dt.files;
        $form.append(input);
      });

      return true;
    });

    ua = navigator.userAgent;
    if (
      ua.indexOf('MSIE') > -1 ||
      ua.indexOf('Trident') > -1 ||
      ua.indexOf('Edge') > -1 ||
      (ua.indexOf('Safari') != -1 && ua.indexOf('Chrome') == -1)
    ) {
      if (ua.indexOf('Safari') != -1 && ua.indexOf('Chrome') == -1) {
        console.log('Using Safari');
        $form[0].setAttribute('onsubmit', 'return false');
      } else {
        console.log('Using IE');
      }
      $('.btn:submit').click(function (event) {
        $form.ajaxSubmit({
          type: 'POST',
          beforeSubmit: function (arr, $form, options) {
            if (arr.length == 0) {
              return false;
            }

            $('#job_form_messages', $form).html(
              AS.renderTemplate('template_uploading_message')
            );

            console.log('ATTACH');
            $('.import-file.file-attached').each(function () {
              var $input = $(this);
              console.log($input);
              arr.push({
                name: 'files[]',
                type: 'file',
                value: $input.data('file'),
              });
            });

            arr.push({ name: 'ajax', value: true });
          },
          success: function (json, status, xhr) {
            var uri_to_resolve;

            if (typeof json === 'string') {
              // In IE8 (older browsers), AjaxForm will use an iframe to deliver this POST.
              // When using an iframe it cannot handle JSON as a response type... so let us
              // grab the HTML string returned and parse it.
              var $responseFromIFrame = $(json);

              if ($responseFromIFrame.is('textarea')) {
                if ($responseFromIFrame.data('type') === 'html') {
                  // it must of errored
                  return handleError($responseFromIFrame.val());
                } else if ($responseFromIFrame.data('type') === 'json') {
                  uri_to_resolve = JSON.parse($responseFromIFrame.val()).uri;
                } else {
                  throw (
                    'jobs.crud: textarea.data-type not currently support - ' +
                    $responseFromIFrame.data('type')
                  );
                }
              } else {
                throw 'jobs.crud: the response text should be wrapped in a textarea for the plugin AjaxForm support';
              }
            } else {
              uri_to_resolve = json.uri;
            }

            $('#job_form_messages', $form).html(
              AS.renderTemplate('template_success_message')
            );

            location.href = AS.app_prefix(
              'resolve/readonly?uri=' + uri_to_resolve
            );
            console.log('SUCCESS!');
          },
          error: function (xhr) {
            console.log('ERROR!');
            handleError(xhr.responseText);
          },
        });
      });
    }
  };

  var hideImportEventsOption = function () {
    $('#js-import-events').hide();

    $('#job_import_type_').change(function () {
      if (
        $('#job_import_type_').val() == 'marcxml_auth_agent' ||
        $('#job_import_type_').val() == 'eac_xml'
      ) {
        $('#js-import-events').show();
      } else {
        $('#js-import-events').hide();
      }
    });
  };

  var hideImportSubjectsOption = function () {
    $('#js-import-subjects').hide();

    $('#job_import_type_').change(function () {
      if ($('#job_import_type_').val() == 'marcxml_auth_agent') {
        $('#js-import-subjects').show();
      } else {
        $('#js-import-subjects').hide();
      }
    });
  };

  var hideImportRepositoryOption = function () {
    $('#js-import-repository').hide();

    $('#job_import_type_').change(function () {
      if ($('#job_import_type_').val() == 'location_csv') {
        $('#js-import-repository').show();
      } else {
        $('#js-import-repository').hide();
      }
    });
  };

  var type = $('#job_type').val();

  $('.linker:not(.initialised)').linker();

  // these were added because it was neccesary to get translation
  $('.translation-placeholder').remove();

  if (type == 'report_job') {
    initReportJobForm();
  } else if (type == 'container_labels_job') {
    initSourceJobForm();
  } else if (type == 'print_to_pdf_job') {
    initSourceJobForm();
  } else if (type == 'find_and_replace_job') {
    initFindAndReplaceJobForm();
  } else if (type == 'import_job') {
    initImportJobForm();
  }

  hideImportEventsOption();
  hideImportSubjectsOption();
  hideImportRepositoryOption();
};

$(init);
