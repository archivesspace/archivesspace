$(function() {

    var $form = $('#jobfileupload');

    var initReportJobForm = function() {

        $("#job_form_messages", $form)
            .html(AS.renderTemplate("template_report_instructions"));
        // we disable to form...
        $('.form-actions .btn-primary').addClass('disabled');

        $(document).triggerHandler("subrecordcreated.aspace", ["date", $form]);
        $('.select-record', $form).on("click", function(event) {
            $('.accordion-toggle').click();
            $('.form-actions .btn-primary').removeClass('disabled');
            event.preventDefault();
            var report = $(this).data('report');
            var $listing = $(this).parent();
            $(this).siblings(".selected-message").removeClass("hide")
            $(this).addClass("hide")
            $listing.removeClass('alert-info').addClass('alert-success');
            $listing.parent().siblings('.report-listing').fadeOut('slow', function() {
                $(this).remove();
            });
        });

        var initLocationReportSubForm = function() {
            $(document).on('change', '#location_report_type', function() {
                var selected_report_type = $(this).val();

                $('.report_type').hide();

                var location_start_linker = $('#report_location_start');
                var location_end_linker = $('#report_location_end');

                if (selected_report_type === 'single_location') {
                    location_end_linker.hide();
                    location_start_linker.find('label').text(location_start_linker.data('singular-label'));
                } else if (selected_report_type === 'location_range') {
                    location_start_linker.find('label').text(location_start_linker.data('range-label'));
                    location_end_linker.find('label').text(location_end_linker.data('range-label'));
                    location_end_linker.show();
                }

                $('.report_type.' + selected_report_type).show();
            });

            $('#location_report_type').trigger('change');
        };

        var initCustomReportSubForm = function() {
            $(document).on('change', '#custom_record_type', function() {
                var selected_record_type = $(this).val();

                $('.record_type').hide();
                $('.record_type.' + selected_record_type).show();
            });
            $('#custom_record_type').trigger('change');
        };

        var initFormatReportSubForm = function() {
            $(document).on('change', '#report_job_format', function() {

                if ($(this).val() == 'csv') {
                    $('.csv_options').show();
                } else {
                    $('.csv_options').hide();
                }
            });
        };

        initLocationReportSubForm();
        initCustomReportSubForm();
        initFormatReportSubForm();
    };

    var initPrintToPdfJobForm = function() {
        $("#print_to_pdf_job_ref_").attr("name", "print_to_pdf_job[source]");
    };

    var initFindAndReplaceJobForm = function() {
        $("#job_form_messages", $form)
            .html(AS.renderTemplate("template_find_and_replace_warning"));

        // init findAndReplaceForm
        var $selectRecordType = $("#find_and_replace_job_record_type_");
        var $selectProperty = $("#find_and_replace_job_property_");

        $selectRecordType.attr('disabled', 'disabled');
        $selectProperty.attr('disabled', 'disabled');

        $("#find_and_replace_job_ref_").attr("name", "find_and_replace_job[base_record_uri]");

        $("#find_and_replace_job_ref_").change(function() {
            var resourceUri = $(this).val();
            if (resourceUri.length) {
                var id = /\d+$/.exec(resourceUri)[0]
                $.ajax({
                    url: AS.app_prefix("/resources/" + id + "/models_in_graph"),
                    success: function(typeList) {
                        var oldVal = $selectRecordType.val();
                        $selectRecordType.empty();
                        $selectRecordType.append($('<option>', {
                                selected: true,
                                disabled: true
                            })
                            .text(" -- select a record type --"));
                        $.each(typeList, function(index, valAndText) {
                            var opts = {
                                value: valAndText[0]
                            };
                            if (oldVal === valAndText[0])
                                opts.selected = true;

                            $selectRecordType.append($('<option>', opts)
                                .text(valAndText[1]));
                        });
                        $selectRecordType.removeAttr('disabled');
                        if (oldVal != $selectRecordType.val())
                            $selectRecordType.triggerHandler('change');
                    }
                });

            }
        });

        $selectRecordType.change(function() {
            var recordType = $(this).val();
            $.ajax({
                url: AS.app_prefix("/schema/" + recordType + "/properties?type=string&editable=true"),
                success: function(propertyList) {
                    $selectProperty.empty();

                    $.each(propertyList, function(index, valAndText) {
                        $selectProperty
                            .append($('<option>', {
                                    value: valAndText[0]
                                })
                                .text(valAndText[1]));
                    });

                    $selectProperty.removeAttr('disabled');
                }
            });
        });
    };

    var initImportJobForm = function() {

        var supportsHTML5MultipleFileInput = function() {
            var input = document.createElement("input");
            input.setAttribute("multiple", "true");
            return input.multiple === true;
        };

        var initFileUploadSection = function() {
            var $dropContainer = $("#files");

            var handleFileInputChange = function() {
                $(".hint", $dropContainer).remove();

                var $input = $(this);

                // if browser supports multiple files, then iterate through each
                // and add them to the list
                if (supportsHTML5MultipleFileInput()) {
                    $(this.files).each(function(idx, file) {
                        var filename = file.name.split("\\").reverse()[0]
                        var $file_html = $(AS.renderTemplate("template_import_file", {
                            filename: filename
                        }));

                        $file_html.data("file", file);
                        $file_html.addClass("file-attached");

                        $input.val("");

                        $dropContainer.append($file_html);
                    });

                    // Otherwise, there's only one file, so create an cloned input for it
                    // This is for older browsers (like IE8) that don't support the new
                    // HTML5 input#file mulitple feature
                } else {
                    var filename = $input.val().split("\\").reverse()[0]
                    var $file_html = $(AS.renderTemplate("template_import_file", {
                        filename: filename
                    }));

                    $file_html.append($input);
                    var $clone = $input.clone();
                    $clone.on("change", handleFileInputChange);
                    $(".fileinput-button", $form).append($clone);

                    $dropContainer.append($file_html);
                }
            };

            $(":file", $form).on("change", handleFileInputChange);

            $dropContainer.on("click", ".btn-remove-file", function() {
                $(this).closest(".import-file").remove();
            });

            $dropContainer.on('dragenter', function(e) {
                e.stopPropagation();
                e.preventDefault();
                $(this).addClass("active");
            }).on('dragover', function(e) {
                e.stopPropagation();
                e.preventDefault();
            }).on('dragleave', function(e) {
                e.stopPropagation();
                e.preventDefault();

                $(this).removeClass("active");
            }).on('drop', function(event) {
                $(this).removeClass("incoming").removeClass("active");

                $.each(event.originalEvent.dataTransfer.files, function(i, file) {
                    var $file_html = $(AS.renderTemplate("template_import_file", {
                        filename: file.name
                    }));
                    $file_html.data("file", file);
                    $file_html.addClass("file-attached");

                    $dropContainer.append($file_html);
                });
            });

            // Only allow drop into the #files container
            $(document).on('dragenter', function(e) {
                e.stopPropagation();
                e.preventDefault();

                $dropContainer.addClass("incoming");

            }).on('dragover', function(e) {
                e.stopPropagation();
                e.preventDefault();

                $dropContainer.addClass("incoming");
            }).on('dragleave', function(e) {
                e.stopPropagation();
                e.preventDefault();

                $dropContainer.removeClass("incoming");
            }).on('drop', function(e) {
                e.stopPropagation();
                e.preventDefault();

                $dropContainer.removeClass("incoming").removeClass("active");
            });
        };


        $("#import_job_import_type_", $form).change(function() {
            $("#job_filenames_", $form)
                .empty()
                .append(AS.renderTemplate("template_fileupload"))
                .slideDown();


            initFileUploadSection();
        });

        $("#import_job_import_type_", $form).trigger("change");

        $form.submit(function() {
            $(".import-file.file-attached").each(function() {
                var $input = $(this);
                const input = document.createElement("input");
                input.type = "file";
                input.name = "files[]";
                input.multiple = true;
                input.style.display = "none";
                var dt = new DataTransfer();
                $(".import-file.file-attached").each(function() {
                    dt.items.add($input.data("file"));
                });
                input.files = dt.files;
                $form.append(input);

            });
            return true;
        });

    };

    var type = $("#job_type").val();

    if (type == "report_job") {
        $("#job_type_fields", $form)
        .empty()
        .html(AS.renderTemplate("template_" + type, {
            id_path: "job_job_params_",
            path: "job[job_params]"
        }));
    } else {
        $("#job_type_fields", $form)
        .empty()
        .html(AS.renderTemplate("template_" + type, {
            id_path: type,
            path: type
        }));
    }
    
    $(".linker:not(.initialised)").linker();

    if (type == "report_job") {
        initReportJobForm();
    } else if (type == "print_to_pdf_job") {
        initPrintToPdfJobForm();
    } else if (type == "find_and_replace_job") {
        initFindAndReplaceJobForm();
    } else if (type == "import_job") {
        initImportJobForm();
    }
});