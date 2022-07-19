//= require agents.crud
//= require subjects.crud
//= require dates.crud
//= require notes.crud
//= require instances.crud
//= require lang_materials.crud
//= require deaccessions.crud
//= require subrecord.crud
//= require rights_statements.crud
//= require form

function SimpleLinkingModal(config) {
  var self = this;
  self.config = config;
  self.page = 1;
  self.currentSelected = undefined;
  self.context_filter_term = [];
  (config.context_filter_term || []).forEach((element, index) => {
    self.context_filter_term.push(JSON.stringify(element));
  });
  self.$modal = AS.openCustomModal(
    'linkResourceModal',
    self.config.title,
    AS.renderTemplate('linker_browsemodal_template', config),
    'large',
    {},
    this
  );
  self.$container = $('.linker-container', self.$modal);
  if (self.config.url_html == undefined) {
    throw 'Cannot load linking modal because the modal config is missing a url';
  }
  self.reload_modal(self.config.url_html);
  self.init_click_handlers();
  self.init_radio_handlers();
}

SimpleLinkingModal.prototype.update_state_from_href = function (href) {
  var self = this;
  var requestParams = decodeURIComponent(href).split('?')[1];
  requestParams = new URLSearchParams(requestParams);

  if (requestParams.has('page')) {
    self.page = new Number(requestParams.get('page'));
  } else if (href == '#') {
    self.page = 1;
  }
  if (requestParams.has('sort')) {
    self.sort = requestParams.get('sort');
  }
  if (requestParams.has('filter_term[]')) {
    self.filter_term = requestParams.get('filter_term[]');
  }
};

SimpleLinkingModal.prototype.init_radio_handlers = function () {
  var self = this;

  // change selected
  function clickRadioHandler(event) {
    event.stopPropagation();
    self.set_selected($(this).val());
  }

  this.$modal.on('click', '.table-search-results input', clickRadioHandler);
  this.$modal.on('click', '.table-search-results tr', function (event) {
    event.preventDefault();
    $('input', $(this)).trigger('click');
  });
};

SimpleLinkingModal.prototype.init_click_handlers = function () {
  var self = this;

  // update the browse table only from JSON endpoint
  function jsonRefreshHandler(event) {
    event.preventDefault();
    self.update_state_from_href($(this).attr('href'));
    self.reload_results_table();
  }

  self.$modal.on('click', '.table-search-results a', jsonRefreshHandler);
  self.$modal.on('click', '.pagination a', jsonRefreshHandler);
  self.$modal.on('click', '.search-listing-filter a', function (event) {
    event.preventDefault();
    var url = $(this).attr('href');
    self.reload_modal(url);
  });
  self.$modal.on('click', '.search-filter button', function (event) {
    event.preventDefault();
    var url = self.config.url_html + '&q=' + $('#filter-text').val();
    self.reload_modal(url);
  });
  self.$modal.on('click', '#addSelectedButton', function (event) {
    event.preventDefault();
    if (self.currentSelected) {
      // closing this way to get proper focus back in main window
      $('.modal-header a', self.$modal).trigger('click');
      self.config.onLink(self.currentSelected);
    }
    return false;
  });
};

SimpleLinkingModal.prototype.set_selected = function (uri) {
  var self = this;
  this.currentSelected = uri;
  $('#addSelectedButton').removeClass('disabled');
  $('tr.selected').removeClass('selected');
  var $input = $(":input[value='" + uri + "']", self.$modal);
  $input.closest('tr').addClass('selected');
};

SimpleLinkingModal.prototype.set_active_page = function (page) {
  var self = this;
  $('ul.pagination li', self.$modal).removeClass('active');
  $($('ul.pagination li', self.$modal)[page]).addClass('active');
};

SimpleLinkingModal.prototype.set_pagination_size = function (last_page) {
  var self = this;
  $('ul.pagination li', self.$modal)
    .toArray()
    .forEach((element, index) => {
      if (index > last_page) {
        $(element).hide();
      } else {
        $(element).show();
      }
    });
};

SimpleLinkingModal.prototype.set_pagination_summary = function (
  offset_first,
  offset_last,
  total_hits
) {
  var self = this;
  $('.record-pane strong:first', self.$modal).html(offset_first);
  $('.record-pane strong:nth(1)', self.$modal).html(offset_last);
  $('.record-pane strong:nth(2)', self.$modal).html(total_hits);
};

// update the results table when it is sorted or paged
SimpleLinkingModal.prototype.reload_results_table = function () {
  var self = this;
  $.ajax({
    url: self.config.url_json,
    type: 'GET',
    dataType: 'json',
    data: {
      page: self.page,
      sort: self.sort,
      type: self.config.types,
      filter_term: self.filter_term,
      linker: true,
      multiplicity: 1,
    },
    success: function (searchData) {
      searchData['config'] = self.config;
      // update pagination
      self.set_pagination_summary(
        searchData.search_data.offset_first,
        searchData.search_data.offset_last,
        searchData.search_data.total_hits
      );
      self.set_pagination_size(searchData.search_data.last_page);
      self.set_active_page(searchData.search_data.this_page);
      // update results table
      var rows = '';
      searchData.search_data.results.forEach(item => {
        rows += AS.renderTemplate('linker_browse_row_template', item);
      });
      $('#tabledSearchResults tbody').html(rows);
      //      self.init_radio_handlers();
      if (self.currentSelected) {
        var $input = $(
          "input[value='" + self.currentSelected + "']",
          self.$modal
        );
        $input.trigger('click');
      }
    },
    error: function (jqXHR, textStatus, errorThrown) {},
  });
};

// update the entire modal with a new html document
SimpleLinkingModal.prototype.reload_modal = function (url) {
  var self = this;
  self.currentSelected = undefined;
  $('#addSelectedButton').addClass('disabled');
  var _data = {
    type: self.config.types,
    context_filter_term: self.context_filter_term || [],
    linker: true,
    multiplicity: 1,
    hide_sort_options: true,
    hide_csv_download: true,
  };

  $.ajax({
    url: url,
    type: 'GET',
    dataType: 'html',
    data: _data,
    success: function (html) {
      self.$container.html(html);
    },
  });
};

// pops up serial modals to ensure resource and parent are determined
function validateResourceAndParent() {
  var $resourceInput = $('#archival_object_form').find(
    'input[name="archival_object[resource]"]'
  );
  var $parentInput = $('#archival_object_form').find(
    'input[name="archival_object[parent]"]'
  );
  if ($resourceInput.val() !== undefined && $resourceInput.val().length < 1) {
    $('#archival_object_form')
      .find('.save-changes :submit')
      .addClass('disabled')
      .attr('disabled', 'disabled');
    // launch modal for selecting the resource
    new SimpleLinkingModal({
      url_html: $resourceInput.data('browse-url-html'),
      url_json: $resourceInput.data('browse-url-json'),
      title: $resourceInput.data('modal-title'),
      primary_button_text: $resourceInput.data('modal-title'),
      types: ['resource'],
      linker: true, //?
      multiplicity: 1,
      onLink: function (resource_uri) {
        let resource_id = resource_uri.replace(/.*\//, '');
        let locationParams = location.href.split('?')[1];
        locationParams = new URLSearchParams(locationParams);
        locationParams.set('resource_id', resource_id);
        history.replaceState(
          {},
          document.title,
          location.href.split('?')[0] + '?' + locationParams.toString()
        );
        $resourceInput.attr('name', 'archival_object[resource][ref]');
        $resourceInput.val(resource_uri);
        $('#archival_object_form')
          .find(':submit')
          .removeClass('disabled')
          .removeAttr('disabled');
        validateResourceAndParent();
      },
    });
  } else if (
    $parentInput.val() !== undefined &&
    $parentInput.val().length < 1
  ) {
    // now do same thing for parent
    var $resourceURI = $('#archival_object_form')
      .find('input[name="archival_object[resource][ref]"]')
      .val();
    new SimpleLinkingModal({
      url_html: $parentInput.data('browse-url-html'),
      url_json: $parentInput.data('browse-url-json'),
      title: $parentInput.data('modal-title'),
      primary_button_text: $parentInput.data('modal-title'),
      cancel_button_text: $parentInput.data('leave-empty'),
      types: ['archival_object'],
      context_filter_term: [
        {
          resource: $resourceURI,
        },
      ],
      linker: true,
      multiplicity: 1,
      onLink: function (parent_uri) {
        let parent_id = parent_uri.replace(/.*\//, '');
        let locationParams = location.href.split('?')[1];
        locationParams = new URLSearchParams(locationParams);
        locationParams.set('archival_object_id', parent_id);
        history.replaceState(
          {},
          document.title,
          location.href.split('?')[0] + '?' + locationParams.toString()
        );
        $parentInput.attr('name', 'archival_object[parent][ref]');
        $parentInput.val(parent_uri);
        validateResourceAndParent();
      },
    });
  }
}

$(function () {
  $('#archival_object_form').on(
    'click',
    '.select-resource :submit',
    function (event) {
      event.preventDefault();
      // reset everything when user clicks "select resource"
      $('#archival_object_form')
        .find('input[name="archival_object[resource][ref]"]')
        .val('');
      $('#archival_object_form')
        .find('input[name="archival_object[resource][ref]"]')
        .attr('name', 'archival_object[resource]');
      $('#archival_object_form')
        .find('input[name="archival_object[parent][ref]"]')
        .val('');
      $('#archival_object_form')
        .find('input[name="archival_object[parent][ref]"]')
        .attr('name', 'archival_object[parent]');
      validateResourceAndParent();
    }
  );

  $.fn.init_archival_object_form = function () {
    $(this).each(function () {
      var $this = $(this);

      if ($this.hasClass('initialised')) {
        return;
      }

      var $levelSelect = $('#archival_object_level_', $this);
      var $otherLevel = $('#archival_object_other_level_', $this);

      var handleLevelChange = function (initialising) {
        if ($levelSelect.val() === 'otherlevel') {
          $otherLevel.removeAttr('disabled');
          if (initialising === true) {
            $otherLevel.closest('.form-group').show();
          } else {
            $otherLevel.closest('.form-group').slideDown();
          }
        } else {
          $otherLevel.attr('disabled', 'disabled');
          if (initialising === true) {
            $otherLevel.closest('.form-group').hide();
          } else {
            $otherLevel.closest('.form-group').slideUp();
          }
        }
      };

      handleLevelChange(true);
      $levelSelect.change(handleLevelChange);
    });
  };

  $(document).bind('loadedrecordform.aspace', function (event, $container) {
    $(
      '#archival_object_form:not(.initialised)',
      $container
    ).init_archival_object_form();
  });

  $('#archival_object_form:not(.initialised)').init_archival_object_form();

  validateResourceAndParent();
});
