//= require jquery.tokeninput

$(function () {
  let resource_edit_path_regex = new RegExp(
    '^' + APP_PATH + 'resources/\\d+/edit$'
  );
  let on_resource_edit_path = window.location.pathname.match(
    resource_edit_path_regex
  );

  $.fn.linker = function () {
    $(this).each(function () {
      var $this = $(this);
      var $linkerWrapper = $this.parents('.linker-wrapper:first');

      if ($this.hasClass('initialised')) {
        return;
      }

      $this.addClass('initialised');

      // this is a bit hacky, but we need to have some input fields present in
      // the form so we don't have to rely on the linker to make sure data
      // persists. we can remove those after the linker does its thing.
      $('.prelinker', $linkerWrapper).remove();

      var config = {
        url: decodeURIComponent($this.data('url')),
        browse_url: decodeURIComponent($this.data('browse-url')),
        span_class: $this.data('span-class'),
        format_template: $this.data('format_template'),
        format_template_id: $this.data('format_template_id'),
        format_property: $this.data('format_property'),
        path: $this.data('path'),
        name: $this.data('name'),
        multiplicity: $this.data('multiplicity') || 'many',
        label_create: $this.data('label_create'),
        label_browse: $this.data('label_browse'),
        label_link: $this.data('label_link'),
        label_create_and_link: $this.data('label_create_and_link'),
        modal_id: $this.data('modal_id') || $this.attr('id') + '_modal',
        sortable: $this.data('sortable') === true,
        types: $this.data('types'),
        exclude_ids: $this.data('exclude') || [],
      };

      config.allow_multiple = config.multiplicity === 'many';

      if (
        config.format_template &&
        config.format_template.substring(0, 2) != '${'
      ) {
        config.format_template = '${' + config.format_template + '}';
      }

      var renderCreateFormForObject = function (form_uri) {
        var $modal = $('#' + config.modal_id);

        var initCreateForm = function (formEl) {
          $('.linker-container', $modal).html(formEl);
          $('#createAndLinkButton', $modal).attr('disabled', null);
          $('form', $modal).ajaxForm({
            data: {
              inline: true,
            },
            beforeSubmit: function () {
              $('#createAndLinkButton', $modal).attr('disabled', 'disabled');
            },
            success: function (response, status, xhr) {
              if ($(response).is('form')) {
                initCreateForm(response);
              } else {
                if (config.multiplicity === 'one') {
                  clearTokens();
                }

                $this.tokenInput('add', {
                  id: response.uri,
                  name: tokenName(response),
                  json: response,
                });
                $this.triggerHandler('change');
                $modal.modal('hide');
              }
            },
            error: function (obj, errorText, errorDesc) {
              $('#createAndLinkButton', $modal).attr('disabled', null);
            },
          });

          $modal.scrollTo('.alert');

          $modal.trigger('resize');
          $(document).triggerHandler('loadedrecordform.aspace', [$modal]);
        };

        $.ajax({
          url: form_uri,
          success: initCreateForm,
        });
        $('#createAndLinkButton', $modal).click(function () {
          $('form', $modal).triggerHandler('submit');
        });
      };

      var showLinkerCreateModal = function () {
        // Ensure all typeahead dropdowns are hidden (sometimes blur leaves them visible)
        $('.token-input-dropdown').hide();

        AS.openCustomModal(
          config.modal_id,
          config.label_create,
          AS.renderTemplate('linker_createmodal_template', config),
          'xl',
          {},
          this
        );
        if ($(this).hasClass('linker-create-btn')) {
          renderCreateFormForObject($(this).data('target'));
        } else {
          renderCreateFormForObject(
            $('.linker-create-btn:first', $linkerWrapper).data('target')
          );
        }
        return false; // IE8 patch
      };

      var initAndShowLinkerBrowseModal = function () {
        var currentlySelected = {};

        var renderItemsInModal = function (page) {
          $.each($this.tokenInput('get'), function () {
            currentlySelected[this.id] = this.json;
          });

          $.ajax({
            url: config.browse_url,
            data: {
              page: 1,
              type: config.types,
              linker: true,
              exclude: config.exclude_ids,
              multiplicity: config.multiplicity,
            },
            type: 'GET',
            dataType: 'html',
            success: function (html) {
              var $modal = $('#' + config.modal_id);

              var $linkerBrowseContainer = $('.linker-container', $modal);

              var initBrowseFormInputs = function () {
                // add some click handlers to allow clicking of the row
                $(':input[name=linker-item]', $linkerBrowseContainer).each(
                  function () {
                    var $input = $(this);
                    $input.click(function (event) {
                      event.stopPropagation();

                      // If one-to-one, currentlySelected should only ever
                      // contain one record
                      if (!config.allow_multiple) {
                        currentlySelected = {};
                        $('tr.selected', $input.closest('table')).removeClass(
                          'selected'
                        );
                      }

                      if (
                        Object.prototype.hasOwnProperty.call(
                          currentlySelected,
                          $input.val()
                        )
                      ) {
                        // remove from the list
                        delete currentlySelected[$input.val()];
                        $input.closest('tr').removeClass('selected');
                      } else {
                        // add to the selected list
                        currentlySelected[$input.val()] = $input.data('object');
                        $input.closest('tr').addClass('selected');
                      }
                    });

                    $('td', $input.closest('tr')).click(function (event) {
                      event.preventDefault();

                      $input.trigger('click');
                    });
                  }
                );

                // select a result if it's currently a selected record
                $.each(currentlySelected, function (uri) {
                  $(":input[value='" + uri + "']", $linkerBrowseContainer)
                    .attr('checked', 'checked')
                    .closest('tr')
                    .addClass('selected');
                });

                $modal.trigger('resize');
              };

              $linkerBrowseContainer.html(html);
              $($linkerBrowseContainer).on(
                'click',
                'a:not(.dropdown-toggle):not(.record-toolbar .btn)',
                function (event) {
                  event.preventDefault();

                  $linkerBrowseContainer.load(
                    event.currentTarget.href,
                    initBrowseFormInputs
                  );
                }
              );

              $($linkerBrowseContainer).on('submit', 'form', function (event) {
                event.preventDefault();

                var $form = $(event.target);
                var method = ($form.attr('method') || 'get').toUpperCase();

                if (method == 'POST') {
                  jQuery.post(
                    $form.attr('action') + '.js',
                    $form.serializeArray(),
                    function (html) {
                      $linkerBrowseContainer.html(html);
                      initBrowseFormInputs();
                    }
                  );
                } else {
                  $linkerBrowseContainer.load(
                    $form.attr('action') + '.js?' + $form.serialize(),
                    initBrowseFormInputs
                  );
                }
              });

              initBrowseFormInputs();
            },
          });
        };

        var addSelected = function () {
          selectedItems = [];
          $('.token-input-delete-token', $linkerWrapper).each(function () {
            $(this).triggerHandler('click');
          });
          $.each(currentlySelected, function (uri, object) {
            $this.tokenInput('add', {
              id: uri,
              name: tokenName(object),
              json: object,
            });
          });
          $('#' + config.modal_id).modal('hide');
          $this.triggerHandler('change');
        };

        // Ensure all typeahead dropdowns are hidden (sometimes blur leaves them visible)
        $('.token-input-dropdown').hide();

        AS.openCustomModal(
          config.modal_id,
          config.label_browse,
          AS.renderTemplate('linker_browsemodal_template', config),
          'xl',
          {},
          this
        );
        renderItemsInModal();
        $('#' + config.modal_id).on('click', '#addSelectedButton', addSelected);
        $('#' + config.modal_id).on(
          'click',
          '.linker-list .pagination .navigation a',
          function () {
            renderItemsInModal($(this).attr('rel'));
          }
        );
        return false; // IE patch
      };

      var formatResults = function (searchData) {
        var formattedResults = [];

        var currentlySelectedIds = [];
        $.each($this.tokenInput('get'), function (obj) {
          currentlySelectedIds.push(obj.id);
        });

        $.each(searchData.search_data.results, function (index, obj) {
          // only allow selection of unselected items
          if ($.inArray(obj.uri, currentlySelectedIds) === -1) {
            formattedResults.push({
              name: tokenName(obj),
              id: obj.id,
              json: obj,
            });
          }
        });
        return formattedResults;
      };

      var addEventBindings = function () {
        $('.linker-browse-btn', $linkerWrapper).on(
          'click',
          initAndShowLinkerBrowseModal
        );
        $('.linker-create-btn', $linkerWrapper).on(
          'click',
          showLinkerCreateModal
        );

        // Initialise popover on demand to improve performance
        $linkerWrapper.one('mouseenter focus', '.has-popover', function () {
          $(document).triggerHandler('init.popovers', [$this.parent()]);
        });
      };

      var clearTokens = function () {
        // as tokenInput plugin won't clear a token
        // if it has an input.. remove all inputs first!
        var $tokenList = $('.token-input-list', $this.parent());
        for (var i = 0; i < $this.tokenInput('get').length; i++) {
          var id_to_remove = $this.tokenInput('get')[i].id.replace(/\//g, '_');
          $('#' + id_to_remove + ' :input', $tokenList).remove();
        }
        $this.tokenInput('clear');
      };

      var enableSorting = function () {
        if ($('.token-input-list', $linkerWrapper).data('sortable')) {
          $('.token-input-list', $linkerWrapper).sortable('destroy');
        }
        $('.token-input-list', $linkerWrapper).sortable({
          items: 'li.token-input-token',
        });
        $('.token-input-list', $linkerWrapper)
          .off('sortupdate')
          .on('sortupdate', function () {
            $this.parents('form:first').triggerHandler('formchanged.aspace');
          });
      };

      var tokensForPrepopulation = function () {
        if ($this.data('multiplicity') === 'one') {
          // If we are on a resource or archival object edit page, and open a top_container modal with a
          // collection_resource linker then we prepopulate the collection_resource field with resource
          // data necessary to perform the search
          let onResource = $('.label.label-info').text() === 'Resource';
          let onArchivalObject =
            $('.label.label-info').text() === 'Archival Object';
          let modalHasResource =
            $('.modal-dialog').find('#collection_resource').length > 0;
          let idMatches = $this[0].id === 'collection_resource';

          if (
            on_resource_edit_path &&
            modalHasResource &&
            idMatches &&
            (onResource || onArchivalObject)
          ) {
            let currentForm = $('#object_container').find('form').first();
            if (onResource) {
              return [
                {
                  id: currentForm.attr('data-update-monitor-record-uri'),
                  name: $('#resource_title_').text(),
                  json: {
                    id: currentForm.attr('data-update-monitor-record-uri'),
                    uri: currentForm.attr('data-update-monitor-record-uri'),
                    title: $('#resource_title_').text(),
                    jsonmodel_type: 'resource',
                  },
                },
              ];
            } else if (onArchivalObject) {
              return [
                {
                  id: $('#archival_object_resource_').attr('value'),
                  name: $('.record-title').first().text(),
                  json: {
                    id: $('#archival_object_resource_').attr('value'),
                    uri: $('#archival_object_resource_').attr('value'),
                    title: $('.record-title').first().text(),
                    jsonmodel_type: 'resource',
                  },
                },
              ];
            }
          }

          if ($.isEmptyObject($this.data('selected'))) {
            return [];
          }
          return [
            {
              id: $this.data('selected').uri,
              name: tokenName($this.data('selected')),
              json: $this.data('selected'),
            },
          ];
        } else {
          if (!$this.data('selected') || $this.data('selected').length === 0) {
            return [];
          }

          return $this.data('selected').map(function (item) {
            if (typeof item == 'string') {
              item = JSON.parse(item);
            }
            return {
              id: item.uri,
              name: tokenName(item),
              json: item,
            };
          });
        }
      };

      // ANW-521: For subjects, we want to have specialized icons based on the subjects' term type.
      var tag_subjects_by_term_type = function (obj) {
        if (obj.json.jsonmodel_type == 'subject') {
          switch (obj.json.first_term_type) {
            case 'cultural_context':
              return 'subject_type_cultural_context';
            case 'function':
              return 'subject_type_function';
            case 'genre_form':
              return 'subject_type_genre_form';
            case 'geographic':
              return 'subject_type_geographic';
            case 'occupation':
              return 'subject_type_occupation';
            case 'style_period':
              return 'subject_type_style_period';
            case 'technique':
              return 'subject_type_technique';
            case 'temporal':
              return 'subject_type_temporal';
            case 'topical':
              return 'subject_type_topical';
            case 'uniform_title':
              return 'subject_type_uniform_title';
            default:
              return '';
          }
        } else {
          return '';
        }
      };

      // ANW-631, ANW-700: Add four_part_id to token name via data source
      function tokenName(object) {
        var title = object.display_string || object.title;

        function output(id) {
          return id + ': ' + title;
        }

        if (object.four_part_id !== undefined) {
          // Data comes from Solr index
          return output(object.four_part_id.split(' ').join('-'));
        } else if (object.digital_object_id !== undefined) {
          // Data comes from Solr index
          return output(object.digital_object_id);
        } else {
          // Data comes from JSON property on data from Solr index
          var idProperties = ['id_0', 'id_1', 'id_2', 'id_3'];
          var fourPartIdArr = idProperties.reduce(function (acc, id) {
            if (object[id] !== undefined) {
              acc.push(object[id]);
            }
            return acc;
          }, []);

          return fourPartIdArr.length > 0
            ? output(fourPartIdArr.join('-'))
            : title;
        }
      }

      var init = function () {
        var tokenInputConfig = $.extend({}, AS.linker_locales, {
          animateDropdown: false,
          preventDuplicates: true,
          allowFreeTagging: false,
          tokenLimit: config.multiplicity === 'one' ? 1 : null,
          caching: false,
          onCachedResult: formatResults,
          onResult: formatResults,
          zindex: 1100,
          tokenFormatter: function (item) {
            var tokenEl = $(
              AS.renderTemplate('linker_selectedtoken_template', {
                item: item,
                config: config,
              })
            );
            tokenEl
              .children('div')
              .children('.icon-token')
              .addClass(config.span_class);
            $('input[name*=resolved]', tokenEl).val(JSON.stringify(item.json));
            return tokenEl;
          },
          resultsFormatter: function (item) {
            var string = item.name;
            var $resultSpan = $(
              "<span class='" +
                item.json.jsonmodel_type +
                "' aria-label='" +
                string +
                "'>"
            );
            var extra_class = tag_subjects_by_term_type(item);
            $resultSpan.text(string);
            $resultSpan.prepend(
              "<span class='icon-token " + extra_class + "'></span>"
            );
            var $resultLi = $("<li role='option'>");
            $resultLi.append($resultSpan);
            return $resultLi[0].outerHTML;
          },
          prePopulate: tokensForPrepopulation(),
          onDelete: function () {
            $this.triggerHandler('change');
          },
          onAdd: function (item) {
            // ANW-521: After adding a subject, find the added node and apply the special class for that node.
            var extra_class = tag_subjects_by_term_type(item);
            var added_node_id = '#' + item.id.replace(/\//g, '_');

            added_node = $(added_node_id);
            added_node
              .children('div')
              .children('.icon-token')
              .addClass(extra_class);

            if (config.sortable && config.allow_multiple) {
              enableSorting();
            }

            //            $this.triggerHandler("change");
            $(document).triggerHandler('init.popovers', [$this.parent()]);
          },
          formatQueryParam: function (q, ajax_params) {
            if (
              $this.tokenInput('get').length > 0 ||
              config.exclude_ids.length > 0
            ) {
              var currentlySelectedIds = $.merge([], config.exclude_ids);
              $.each($this.tokenInput('get'), function (i, obj) {
                currentlySelectedIds.push(obj.id);
              });

              ajax_params.data['exclude[]'] = currentlySelectedIds;
            }
            if (config.types && config.types.length > 0) {
              ajax_params.data['type'] = config.types;
            }

            return (q + '*').toLowerCase();
          },
        });

        setTimeout(function () {
          $this.tokenInput(config.url, tokenInputConfig);
          $(
            '> :input[type=text]',
            $('.token-input-input-token', $this.parent())
          )
            .attr('placeholder', AS.linker_locales.hintText)
            .attr('aria-label', config.label)
            .attr('role', 'searchbox')
            .attr('aria-multiline', 'false');
          $(
            '> :input[type=text]',
            $('.token-input-input-token', $this.parent())
          ).addClass('form-control');

          $this.parent().addClass('multiplicity-' + config.multiplicity);

          if (config.sortable && config.allow_multiple) {
            enableSorting();
            $linkerWrapper.addClass('sortable');
          }

          // This is part of automatically executing a search for the current resource on the browse top
          // containers modal when opened from the edit resource or archival object pages.
          // If this setTimeout is for the last linker in the modal, only then is it safe to execute the search
          let lastLinker = $('.modal-dialog').find('.linker').last();
          let isLastLinker = lastLinker.attr('id') === $this.attr('id');
          let onResource = $('.label.label-info').text() === 'Resource';
          let onArchivalObject =
            $('.label.label-info').text() === 'Archival Object';
          let modalHasResource =
            $('.modal-dialog').find('#collection_resource').length > 0;
          let resultsEmpty =
            $('.modal-dialog').find('.table-search-results').length < 1;

          if (
            on_resource_edit_path &&
            modalHasResource &&
            resultsEmpty &&
            isLastLinker &&
            (onResource || onArchivalObject)
          ) {
            $('.modal-dialog').find("input[type='submit']").click();
          }
        });

        addEventBindings();
      };

      init();
    });
  };
});

$(document).ready(function () {
  $(document).bind('loadedrecordsubforms.aspace', function (event, $container) {
    $(
      '.linker-wrapper:visible > .linker:not(.initialised)',
      $container
    ).linker();
    // we can go ahead and init dropdowns ( such as those in the toolbars )
    $('#archives_tree_toolbar .linker:not(.initialised)').linker();
  });

  $(document).bind(
    'subrecordcreated.aspace',
    function (event, object_name, subform) {
      $('.linker:not(.initialised)', subform).linker();
    }
  );
});
