//= require form
//= require agents.crud
//= require agents.show
//= require merge_dropdown
//= require subrecord_merge.crud
//= require notes_merge.crud
//= require dates.crud
//= require related_agents.crud
//= require rights_statements.crud
//= require add_event_dropdown
//= require notes_override.crud
//= require embedded_search

$(function () {
  $('button.preview-merge').on('click', function () {
    var $form = $('form:eq( 4 )');
    AS.openCustomModal(
      'mergePreviewModal',
      $(this).text(),
      "<div class='alert alert-info'>Loading...</div>",
      'xl',
      this
    );
    $.ajax({
      url: $form.attr('action') + '?dry_run=true',
      type: 'POST',
      data: $form.serializeArray(),
      success: function (html) {
        $('.alert', '#mergePreviewModal').replaceWith(
          AS.renderTemplate('modal_quick_template', { message: html })
        );
        $(window).trigger('resize');
      },
    });
  });

  $('button.do-merge').on('click', function () {
    $('form:eq( 4 )').submit();
  });

  // run target side code to color replaceable items
  $(function () {
    // disable reorder handle, but only for target side
    $('.merge-group-left .drag-handle').removeClass('drag-handle');
    $('.merge-group-left .ui-sortable-handle').removeClass(
      'ui-sortable-handle'
    );
  });

  // run merge_candidate side code to color replaceable items
  $(function () {
    var enableReplace = function (items) {
      items.each(function () {
        $(this).find('.replace-control').show();
        $(this).find('.subreplace-control').show();
      });
    };

    var disableReplace = function (items) {
      items.each(function () {
        $(this).find('.replace-control input').prop('checked', false);
        $(this).find('.subreplace-control input').prop('checked', false);
        $(this).find('.append-control input').prop('checked', false);

        $(this).find('.replace-control').hide();
        $(this).find('.subreplace-control').hide();
      });
    };

    var clear_replace = function (section) {
      section.find('li').each(function () {
        $(this).removeClass('merge-group-even');
        $(this).removeClass('merge-group-odd');
        disableReplace($(this));

        $(this)
          .find('.subrecord-form-fields')
          .each(function () {
            $(this).removeClass('merge-group-even');
            $(this).removeClass('merge-group-odd');
          });

        $(this)
          .find('.subrecord-form-fields')
          .each(function () {
            $(this).removeClass('merge-group-even');
            $(this).removeClass('merge-group-odd');
          });
      });
    };

    // for each li element in section on left (target), enable replace and color corrsponding element in section on right (merge_candidate)
    var find_replace_elements = function (section) {
      var left_group_parent_id = section.attr('id');
      var right_group_parent_id = '#'.concat(
        left_group_parent_id.replace('left', 'right')
      );

      clear_replace($(right_group_parent_id));

      section.find('li').each(function (i) {
        gclass = i % 2 == 0 ? 'merge-group-even' : 'merge-group-odd';
        left_li = $(this);
        right_li = $(
          right_group_parent_id.concat(' li:nth-of-type(', i + 1, ')')
        );

        if (right_li.length > 0) {
          left_li.addClass(gclass);
          right_li.addClass(gclass);

          enableReplace(right_li);
        }
      });
    };

    // run for first time for all merge groups to color and enable all replacements
    $('.merge-group-left').each(function () {
      if (!$(this).hasClass('merge-no-color')) {
        find_replace_elements($(this));
      }
    });

    // clicking on add hides replace and vice versa
    $('.merge-group-right li').each(function () {
      var li_parent = $(this);

      var append_box = $(this).find('.append-control input').first();
      append_box.click(function () {
        var append_box_checked = append_box.is(':checked');

        li_parent.find('.replace-control input').each(function () {
          $(this).prop('checked', false);
        });

        li_parent.find('.subreplace-control input').each(function () {
          $(this).prop('checked', false);

          if (append_box_checked == true) {
            $(this).prop('disabled', true);
          } else {
            $(this).prop('disabled', false);
          }
        });
      });

      var replace_box = $(this).find('.replace-control input').first();
      replace_box.click(function () {
        var replace_box_checked = replace_box.is(':checked');

        li_parent.find('.append-control input').each(function () {
          $(this).prop('checked', false);
        });

        li_parent.find('.subreplace-control input').each(function () {
          $(this).prop('checked', function (i, val) {
            if (replace_box_checked == true) {
              return true;
            } else {
              return false;
            }
          });

          $(this).prop('disabled', function (i, val) {
            if (replace_box_checked == true) {
              return true;
            } else {
              return false;
            }
          });
        });
      });
    });

    // run for section anytime order is shifted in a group
    $('.merge-group-right .merge-replace-enabled .subrecord-form-list').on(
      'mergesubformchanged.aspace',
      function (event) {
        parent_section_id = $(this)
          .parents('section')
          .parents('section')
          .attr('id');
        parent_section_id_left = '#'.concat(
          parent_section_id.replace('right', 'left')
        );

        find_replace_elements($(parent_section_id_left));
      }
    );
  });

  // run code to match up section heights
  $(function () {
    // this is basically a rewrite of JQuery's matchHeight() function. Not sure why it's not working in some cases
    var equalHeightId = function (div1, div2) {
      var div1h = div1.height();
      var div2h = div2.height();

      if (div1h > div2h) {
        div2.height(div1h);
      } else {
        div1.height(div2h);
      }
    };

    equalHeightId($('#title_left'), $('#title_right'));

    equalHeightId($('#basic_information_left'), $('#basic_information_right'));

    equalHeightId(
      $('#agent_agent_record_identifier_left'),
      $('#agent_agent_record_identifier_right')
    );

    equalHeightId(
      $('#agent_agent_record_control_left'),
      $('#agent_agent_record_control_right')
    );

    equalHeightId(
      $('#agent_agent_other_agency_code_left'),
      $('#agent_agent_other_agency_code_right')
    );

    equalHeightId(
      $('#agent_agent_conventions_declaration_left'),
      $('#agent_agent_conventions_declaration_right')
    );

    equalHeightId(
      $('#agent_agent_maintenance_history_left'),
      $('#agent_agent_maintenance_history_right')
    );

    equalHeightId(
      $('#agent_agent_source_left'),
      $('#agent_agent_source_right')
    );

    equalHeightId(
      $('#agent_agent_alternate_set_left'),
      $('#agent_agent_alternate_set_right')
    );

    equalHeightId(
      $('#agent_agent_identifier_left'),
      $('#agent_agent_identifier_right')
    );

    equalHeightId($('#agent_names_left'), $('#agent_names_right'));

    equalHeightId(
      $('#agent_dates_of_existence_left'),
      $('#agent_dates_of_existence_right')
    );

    equalHeightId(
      $('#agent_agent_gender_left'),
      $('#agent_agent_gender_right')
    );

    equalHeightId($('#agent_agent_place_left'), $('#agent_agent_place_right'));

    equalHeightId(
      $('#agent_agent_occupation_left'),
      $('#agent_agent_occupation_right')
    );

    equalHeightId(
      $('#agent_agent_function_left'),
      $('#agent_agent_function_right')
    );

    equalHeightId($('#agent_agent_topic_left'), $('#agent_agent_topic_right'));

    equalHeightId(
      $('#agent_used_language_left'),
      $('#agent_used_language_right')
    );

    equalHeightId(
      $('#agent_contact_details_left'),
      $('#agent_contact_details_right')
    );

    equalHeightId($('#agent_notes_left'), $('#agent_notes_right'));

    equalHeightId(
      $('#agent_related_agents_left'),
      $('#agent_related_agents_right')
    );

    equalHeightId(
      $('#agent_external_documents_left'),
      $('#agent_external_documents_right')
    );

    equalHeightId(
      $('#agent_agent_resources_left'),
      $('#agent_agent_resources_right')
    );
  });
});
