//= require jquery.MultiFile

$(function() {

  var initImportJobForm = function() {
    var $form = $('#jobfileupload');

    // e.g. fileFormatsAccepted = 'xml|csv';
    var initFileUploadSection = function(fileFormatsAccepted) {
      var multiFileWidgetOpts = {
        list: '#files',
        STRING: {
          remove: '<span class="btn btn-mini"><span class="icon icon-trash"></span></span>'
        }
      };

      // Not sure if we want client side validation yet...
      //if (fileFormatsAccepted) {
      //  multiFileWidgetOpts['accept'] = fileFormatsAccepted;
      //}

      $('#fileupload', $form).MultiFile(multiFileWidgetOpts);

      var $dropContainer = $("#files");

      $dropContainer.on('dragenter', function (e) {
        e.stopPropagation();
        e.preventDefault();
        $(this).addClass("active");
      }).on('dragover', function (e) {
            e.stopPropagation();
            e.preventDefault();
          }).on('dragleave', function (e) {
            e.stopPropagation();
            e.preventDefault();

            $(this).removeClass("active");
          }).on('drop', function (event) {
            $(this).removeClass("incoming").removeClass("active");

            $.each(event.originalEvent.dataTransfer.files, function(i ,file) {
              var $file_html = $('<div class="MultiFile-label"><a class="MultiFile-remove" href="#fileupload_wrap"><span class="btn btn-mini"><span class="icon icon-trash"></span></span></a> <span class="MultiFile-title"></span></div>');
              $file_html.data("file", file);
              $file_html.addClass("file-attached");
              $file_html.find(".MultiFile-title").text(file.name);
              $file_html.find(".MultiFile-remove").click(function() {
                $file_html.remove();
              });
              $dropContainer.append($file_html);
            });
          });

      // Only allow drop into the #files container
      $(document).on('dragenter', function (e) {
        e.stopPropagation();
        e.preventDefault();

        $dropContainer.addClass("incoming");

      }).on('dragover', function (e) {
            e.stopPropagation();
            e.preventDefault();

            $dropContainer.addClass("incoming");
          }).on('dragleave', function (e) {
            e.stopPropagation();
            e.preventDefault();

            $dropContainer.removeClass("incoming");
          }).on('drop', function (e) {
            e.stopPropagation();
            e.preventDefault();

            $dropContainer.removeClass("incoming").removeClass("active");
          });
    };

    $("#job_import_type_", $form).change(function() {
      if ($(this).val() === "") {
        $("#noImportTypeSelected", $form).show();
        $("#job_filenames_", $form).hide();

      } else {
        $("#noImportTypeSelected", $form).hide();
        $("#job_filenames_", $form)
            .empty()
            .append(AS.renderTemplate("template_fileupload"))
            .slideDown();

        var fileFormat;
        if ($(this).val().indexOf("csv") >= 0) {
          fileFormat = "csv";
        } else if ($(this).val().indexOf("xml") >= 0) {
          fileFormat = "xml";
        }

        initFileUploadSection(fileFormat);
      }
    });
    $("#job_import_type_", $form).trigger("change");

    initFileUploadSection();

    var $progress = $("#uploadProgress", $form)
    var $progressBar = $(".bar", $progress)

    $form.ajaxForm({
      beforeSubmit: function(arr, $form, options) {
        $(".btn, a, :input", $form).attr("disabled", "disabled").addClass("disabled");
        $progress.show();
        $(".MultiFile-label.file-attached").each(function() {
          var $input = $(this);
          arr.push({
            name: "files[]",
            type: "file",
            value: $input.data("file")
          });
        });
      },
      uploadProgress: function(event, position, total, percentComplete) {
        var percentVal = percentComplete + '%';
        $progressBar.width(percentVal)
        //percent.html(percentVal);
      },
      success: function(json) {
        var percentVal = '100%';
        $progressBar.width(percentVal)
        $progress.removeClass("active").removeClass("progress-striped");
        $progressBar.addClass("bar-success");
        $("#successMessage").show();
        location.href = APP_PATH + "resolve/readonly?uri="+json.uri;
      },
      error: function(xhr) {
        $(".content-pane > .container").html(xhr.responseText);
        initImportJobForm();
      },
      complete: function(xhr) {
        //console.log(xhr);
      }
    });
  };

  initImportJobForm();
});