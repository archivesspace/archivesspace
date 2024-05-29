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

//= require ajaxtree
//= require tree_renderers
//= require tree_toolbar
//= require tree_resizer
//= require largetree

function ParentPickingRenderer() {
  ResourceRenderer.call(this);

  this.nodeTemplate = $(
    '<div class="table-row"> ' +
      '  <div class="table-cell no-drag-handle"></div>' +
      '  <div class="table-cell title"><span class="indentor"><button class="expandme" aria-expanded="false"><i class="expandme-icon glyphicon glyphicon-chevron-right"></i></button></span> </div>' +
      '  <div class="table-cell resource-level"></div>' +
      '  <div class="table-cell resource-type"></div>' +
      '  <div class="table-cell resource-container"></div>' +
      '  <div class="table-cell resource-identifier"></div>' +
      '</div>'
  );

  this.newNodeTemplate = $(
    '<div class="table-row"> ' +
      '  <div class="table-cell no-drag-handle"></div>' +
      '  <div class="table-cell title"><span class="indentor"><button class="expandme" aria-expanded="false"><i class="expandme-icon glyphicon glyphicon-chevron-right"></i></button></span> </div>' +
      '  <div class="table-cell resource-level"></div>' +
      '  <div class="table-cell resource-type"></div>' +
      '  <div class="table-cell resource-container"></div>' +
      '  <div class="table-cell resource-identifier"></div>' +
      '</div>'
  );
}

ParentPickingRenderer.prototype = Object.create(ResourceRenderer.prototype);

ParentPickingRenderer.prototype.get_new_node_template = function () {
  return this.newNodeTemplate.clone(false);
};

ParentPickingRenderer.prototype.add_node_columns = function (row, node) {
  ResourceRenderer.prototype.add_node_columns.call(this, row, node);
  // undo the TreeIDs hash fragment inserted when the row was rendered
  row.find('.record-title').attr('href', '#');
};

function TreeLinkingModal(config) {
  var self = this;
  self.config = config;
  self.$modal = AS.openCustomModal(
    'linkResourceModal',
    config.title,
    AS.renderTemplate('linker_browsemodal_template', config),
    'full',
    {},
    this
  );
  self.$modal.find('#addSelectedButton').addClass('disabled');
  self.position = 0;
  let datasource_url =
    RESOURCES_URL + '/' + config.root_record_uri.replace(/.*\//, '') + '/tree';
  self.datasource = new TreeDataSource(datasource_url);
  self.renderer = new ParentPickingRenderer();
  self.$container = $('.linker-container');
  self.$container.addClass('largetree-container');
  self.large_tree = new LargeTree(
    self.datasource,
    self.$container,
    config.root_record_uri,
    true,
    self.renderer,
    function (rootNode) {
      self.$container.find('.record-title').attr('href', '#');
      function menuSelectHandler(level) {
        // remove any existing placeholder row
        if (self.inserted_row != undefined) {
          self.inserted_row.remove();
        }
        inserted_row = self.renderer.get_new_node_template();
        inserted_row.addClass('largetree-node indent-level-' + level);
        inserted_row.addClass('spawn-placeholder');
        inserted_row.addClass('current');
        inserted_row.find('button.expandme').css('visibility', 'hidden');
        inserted_row.find('.title').append($(SPAWN_PLACEHOLDER_TEXT));
        self.inserted_row = inserted_row;
        self.$modal.find('#addSelectedButton').removeClass('disabled');
        if (self.menu) {
          self.menu.remove();
        }
      }
      if (rootNode.child_count == 0) {
        // this will be an only child of the root record, so no need to choose anything
        menuSelectHandler(1);
        self.$container.find('.root-row').after(self.inserted_row);
        return;
      }
      self.$container.on('click', '.expandme', function (e) {
        e.preventDefault();
        e.stopPropagation();
        self.$modal.trigger('resize');
      });
      self.$container.on('click', '.table-row.largetree-node', function (e) {
        e.preventDefault();
        self.selected_row = $(this);
        if (self.menu) {
          self.menu.remove();
        }
        self.menu = $('<ul>').addClass('dropdown-menu largetree-dropdown-menu');
        self.menu.append(
          $(
            '<li class="dropdown-item"><a href="javascript:void(0)" class="add-items-before">' +
              SPAWN_MENU_ITEMS.before +
              '</a></li>'
          )
        );
        self.menu.append(
          $(
            '<li class="dropdown-item"><a href="javascript:void(0)" class="add-items-as-children">' +
              SPAWN_MENU_ITEMS.child +
              '</a></li>'
          )
        );
        self.menu.append(
          $(
            '<li class="dropdown-item"><a href="javascript:void(0)" class="add-items-after">' +
              SPAWN_MENU_ITEMS.after +
              '</a></li>'
          )
        );
        self.$modal.append(self.menu);
        self.menu.css('position', 'absolute');
        self.menu.css(
          'top',
          self.selected_row.offset().top + self.selected_row.height()
        );
        self.menu.css(
          'left',
          self.selected_row.offset().left +
            Number(self.selected_row.data('level')) * 24
        );
        self.menu.css('z-index', 1000);
        self.menu.show();
        self.menu.find('a:first').focus();

        self.menu.on('keydown', function (event) {
          if (event.keyCode == 27) {
            //escape
            self.menu.remove();
            event.stopPropagation();
            event.preventDefault();
            return false;
          } else if (event.keyCode == 38) {
            //up arrow
            if ($(event.target).closest('li').prev().length > 0) {
              $(event.target).closest('li').prev().find('a').focus();
            }
            return false;
          } else if (event.keyCode == 40) {
            //down arrow
            if ($(event.target).closest('li').next().length > 0) {
              $(event.target).closest('li').next().find('a').focus();
            }
            return false;
          }

          return true;
        });

        self.menu.on('click', '.add-items-before', function () {
          menuSelectHandler(self.selected_row.data('level'));
          self.selected_row.before(self.inserted_row);
          if (
            self.inserted_row.closest('.table-row-group').prev('.root-row')
              .length < 1
          ) {
            self.parent_uri = self.inserted_row
              .closest('.table-row-group')
              .prev('.largetree-node')
              .data('uri');
          }
          self.position = self.selected_row.data('position');
        });
        self.menu.on('click', '.add-items-as-children', function () {
          self.large_tree.expandNode(self.selected_row, function () {
            menuSelectHandler(self.selected_row.data('level') + 1);
            if (
              self.selected_row.next() &&
              self.selected_row.next().hasClass('table-row-group')
            ) {
              // the selected parent has children, so insert as their sibling
              self.selected_row
                .next()
                .find('.largetree-node')
                .first()
                .before(self.inserted_row);
            } else {
              // this would be an only child of the parent
              self.selected_row.after(self.inserted_row);
            }
            self.parent_uri = self.selected_row.data('uri');
            self.position = 0;
          });
        });

        self.menu.on('click', '.add-items-after', function () {
          menuSelectHandler(self.selected_row.data('level'));
          if (
            self.selected_row.next() &&
            self.selected_row.next().hasClass('table-row-group')
          ) {
            // the selected predecessor has children, so insert after them
            self.selected_row.next().after(self.inserted_row);
          } else {
            // this would be an only child of the parent
            self.selected_row.after(self.inserted_row);
          }
          self.parent_uri = self.inserted_row
            .closest('.table-row-group')
            .prev('.largetree-node')
            .data('uri');
          self.position = self.selected_row.data('position') + 1;
        });

        return true;
      });
    }
  );

  self.$modal.on('click', '#addSelectedButton', function (event) {
    event.preventDefault();
    // parent_uri may be undef but position should always be an int
    self.config.onLink(self.parent_uri, self.position);
    // closing this way to get proper focus back in main window
    $('.modal-header button', self.$modal).trigger('click');
    return false;
  });
}

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
    'full',
    {},
    this
  );
  self.$container = $('.linker-container', self.$modal);
  if (self.config.url_html == undefined) {
    throw 'Cannot load linking modal because the modal config is missing a url';
  }
  self.reload_modal(self.config.url_html);
  self.$modal.trigger('resize');
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
      $('.modal-header button', self.$modal).trigger('click');
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
  var $positionInput = $('#archival_object_form').find(
    'input[name="archival_object[position]"]'
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
          .attr('disabled', null);
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
    new TreeLinkingModal({
      root_record_uri: $resourceURI,
      title: $parentInput.data('modal-title'),
      primary_button_text: $parentInput.data('modal-title'),
      onLink: function (parent_uri, position) {
        $positionInput.val(position);
        if (parent_uri == undefined) {
          return;
        }
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
          $otherLevel.attr('disabled', null);
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
