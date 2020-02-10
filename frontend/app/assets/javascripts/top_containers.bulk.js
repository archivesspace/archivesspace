//= require tablesorter/jquery.tablesorter.min

/***************************************************************************
 * BulkContainerSearch - provides all the behaviour to the ajax search
 * and selection of records.
 */
function BulkContainerSearch($search_form, $results_container, $toolbar) {
  this.$search_form = $search_form;
  this.$results_container = $results_container;
  this.$toolbar = $toolbar;

  this.setup_form();
  this.setup_results_list();
}

BulkContainerSearch.prototype.setup_form = function() {
  var self = this;

  $(document).trigger("loadedrecordsubforms.aspace", this.$search_form);

  this.$search_form.on("submit", function(event) {
    event.preventDefault();
    self.perform_search(self.$search_form.serializeArray());
  });
};

BulkContainerSearch.prototype.perform_search = function(data) {
  var self = this;

  self.$results_container.closest(".row").show();
  self.$results_container.html(AS.renderTemplate("template_bulk_operation_loading"));

  $.ajax({
    url: AS.app_prefix("top_containers/bulk_operations/search"),
    data: data,
    type: "post",
    success: function(html) {
      $.rails.enableFormElements(self.$search_form);
      self.$results_container.html(html);
      self.setup_table_sorter();
      self.update_button_state();
    },
    error: function(jqXHR, textStatus, errorThrown) {
      $.rails.enableFormElements(self.$search_form);
      var html = AS.renderTemplate("template_bulk_operation_error_message", {message: jqXHR.responseText})
      self.$results_container.html(html);
      self.update_button_state();
    }
  });
};

BulkContainerSearch.prototype.setup_results_list = function(docs) {
  var self = this;

  self.$results_container.on("click", "#select_all", function(event) {
    var $checkbox = $(this);
    if ($checkbox.is(":checked")) {
      $("tbody :checkbox:not(:checked)", self.$results_container).trigger("click");
    } else {
      $("tbody :checkbox:checked", self.$results_container).trigger("click");
    }
  });

  self.$results_container.on("click", ":checkbox", function(event) {
    event.stopPropagation();

    var $checkbox = $(this);
    var $row = $checkbox.closest("tr");
    $row.toggleClass("selected");
    var $first_row_state = $row[0].className

    if (event.altKey) {
	$row = $row.prev();
	while ($row[0] != null && $row[0].className != $first_row_state) {
	    $row.find(":checkbox").click();
	    $row = $row.prev();
	}
    }

    self.update_button_state();
  });

  self.$results_container.on("click", "td", function(event) {
    $(this).closest("tr").find(":checkbox").trigger("click");
  });
};

BulkContainerSearch.prototype.update_button_state = function() {
  var self = this;
  var checked_boxes = $("tbody :checkbox:checked", self.$results_container);
  var delete_btn = self.$toolbar.find(".btn");

  if (checked_boxes.length > 0) {
    var selected_records = $.makeArray(checked_boxes.map(function() {return $(this).val();}));
    delete_btn.data("form-data", {
      record_uris: selected_records
    });
    delete_btn.removeClass("disabled").removeAttr("disabled");
  } else {
    delete_btn.data("form-data", {});
    delete_btn.addClass("disabled").attr("disabled", "disabled");
  }
};

BulkContainerSearch.prototype.setup_table_sorter = function() {
  function padNumber(number) {
    // Get rid of preceding zeros from numbers (so 003 will sort with 3 instead of in the hundreds)
    // Then pad it (so 10 doesn't sort between 1 and 2)
    number = parseInt(number).toString()
    return  (new Array(255).join("#") + number).slice(-255)
  }

  function parseIndicator(value) {
    // Creates a string of alternating number/non-number values separated by commas for indicator sort
    if (!value || value.length === 0) {
      return value
    }

    let isNumber = !isNaN(parseInt(value[0]))

    let valueArray = [value[0]]
    let valueArrayCurrentIndex = 0;
    for (i = 1; i < value.length; i++) {
      if (!isNumber) {
        if (isNaN(parseInt(value[i]))) {
          valueArray[valueArrayCurrentIndex] += value[i]
        } else {
          valueArray[valueArrayCurrentIndex] = valueArray[valueArrayCurrentIndex].trim()
          valueArrayCurrentIndex += 1
          valueArray[valueArrayCurrentIndex] = value[i]
          isNumber = true
        }
      } else {
        if (isNaN(parseInt(value[i]))) {
          valueArray[valueArrayCurrentIndex] = padNumber(valueArray[valueArrayCurrentIndex])
          valueArrayCurrentIndex += 1
          valueArray[valueArrayCurrentIndex] = value[i]
          isNumber = false
        } else {
          valueArray[valueArrayCurrentIndex] += value[i]
        }
      }
    }

    if (!isNaN(parseInt(valueArray[valueArray.length - 1]))) {
      valueArray[valueArray.length - 1] = padNumber(valueArray[valueArray.length - 1])
    }

    return valueArray.toString()
  };

  var tablesorter_opts = {
    // only sort on the second row of header columns
    selectorHeaders: "thead tr.sortable-columns th",
    // disable sort on the checkbox column
    headers: {
        0: { sorter: false}
    },
    // default sort: Collection, Series, Indicator
    sortList: [[1,0],[2,0],[4,0]],
    // customise text extraction to pull only the first collection/series
    textExtraction: function(node) {
      var $node = $(node);

      if ($node.hasClass("top-container-collection")) {
        return $node.find(".collection-identifier:first").text().trim();
      } else if ($node.hasClass("top-container-series")) {
        var level = $node.find(".series-level:first").text().trim();
        var identifier = $node.find(".series-identifier:first").text().trim();

        if ((level+identifier).length > 0) {
          return level + "-" + identifier;
        } else {
          return "";
        }
      } else if ($node.hasClass("top-container-indicator")) {
        var value = $node.text().trim();
        
        // turn the indicator into a string of alternating non-number/padded-number values separated by commas for sorting
        // eg "box,#############11,folder,#############4"
        return parseIndicator(value);
      }

      return $node.text().trim();
    }
  };
  this.$results_container.find("table").tablesorter(tablesorter_opts);
};

BulkContainerSearch.prototype.get_selection = function() {
  var self = this;
  var results = [];

  self.$results_container.find("tbody :checkbox:checked").each(function(i, checkbox) {
    results.push({
      uri: checkbox.value,
      display_string: $(checkbox).data("display-string"),
      row: $(checkbox).closest("tr")
    });
  });

  return results;
};


/***************************************************************************
 * BulkActionIlsHoldingUpdate - ILS bulk action
 *
 */
function BulkActionIlsHoldingUpdate(bulkContainerSearch) {
  this.bulkContainerSearch = bulkContainerSearch;
  this.MENU_ID = "bulkActionUpdateIlsHolding";

  this.setup_menu_item();
};


BulkActionIlsHoldingUpdate.prototype.setup_update_form = function($modal) {
  var self = this;

  var $form = $modal.find("form");

  $form.on("submit", function(event) {
    event.preventDefault();
    self.perform_update($form, $modal);
  });
};


BulkActionIlsHoldingUpdate.prototype.perform_update = function($form, $modal) {
  var self = this;

  $.ajax({
    url:AS.app_prefix("top_containers/bulk_operations/update"),
    data: $form.serializeArray(),
    type: "post",
    success: function(html) {
      $form.replaceWith(html);
      $modal.trigger("resize.modal");
    },
    error: function(jqXHR, textStatus, errorThrown) {
      var error = AS.renderTemplate("template_bulk_operation_error_message", {message: jqXHR.responseText});
      $('#alertBucket').replaceWith(error);
    }
  });
};

BulkActionIlsHoldingUpdate.prototype.setup_menu_item = function() {
  var self = this;

  self.$menuItem = $("#" + self.MENU_ID, self.bulkContainerSearch.$toolbar);

  self.$menuItem.on("click", function(event) {
    self.show();
  });
};


BulkActionIlsHoldingUpdate.prototype.show = function() {
  var dialog_content = AS.renderTemplate("bulk_action_update_ils_holding", {
    selection: this.bulkContainerSearch.get_selection()
  });

  var $modal = AS.openCustomModal("bulkUpdateModal", this.$menuItem[0].text, dialog_content, 'full');

  this.setup_update_form($modal);
};


/***************************************************************************
 * BulkActionContainerProfileUpdate - Container Profile bulk action
 *
 */
function BulkActionContainerProfileUpdate(bulkContainerSearch) {
  this.bulkContainerSearch = bulkContainerSearch;
  this.MENU_ID = "bulkActionUpdateContainerProfile";

  this.setup_menu_item();
};


BulkActionContainerProfileUpdate.prototype.setup_update_form = function($modal) {
  var self = this;

  var $form = $modal.find("form");

  $(document).trigger("loadedrecordsubforms.aspace", [$form]);

  $form.on("submit", function(event) {
    event.preventDefault();
    self.perform_update($form, $modal);
  });
};


BulkActionContainerProfileUpdate.prototype.perform_update = function($form, $modal) {
  var self = this;

  $.ajax({
    url: AS.app_prefix("top_containers/bulk_operations/update"),
    data: $form.serializeArray(),
    type: "post",
    success: function(html) {
      $form.replaceWith(html);
      $modal.trigger("resize.modal");
    },
    error: function(jqXHR, textStatus, errorThrown) {
      var error = AS.renderTemplate("template_bulk_operation_error_message", {message: jqXHR.responseText});
      $('#alertBucket').replaceWith(error);
    }
  });
};

BulkActionContainerProfileUpdate.prototype.setup_menu_item = function() {
  var self = this;

  self.$menuItem = $("#" + self.MENU_ID, self.bulkContainerSearch.$toolbar);

  self.$menuItem.on("click", function(event) {
    self.show();
  });
};


BulkActionContainerProfileUpdate.prototype.show = function() {
  var dialog_content = AS.renderTemplate("bulk_action_update_container_profile", {
    selection: this.bulkContainerSearch.get_selection()
  });

  var $modal = AS.openCustomModal("bulkUpdateModal", this.$menuItem[0].text, dialog_content, 'full');

  this.setup_update_form($modal);
};


/***************************************************************************
 * BulkActionLocationUpdate - Location bulk action
 *
 */
function BulkActionLocationUpdate(bulkContainerSearch) {
  this.bulkContainerSearch = bulkContainerSearch;
  this.MENU_ID = "bulkActionUpdateLocation";

  this.setup_menu_item();
};


BulkActionLocationUpdate.prototype.setup_update_form = function($modal) {
  var self = this;

  var $form = $modal.find("form");

  $(document).trigger("loadedrecordsubforms.aspace", [$form]);

  $form.on("submit", function(event) {
    event.preventDefault();
    self.perform_update($form, $modal);
  });
};


BulkActionLocationUpdate.prototype.perform_update = function($form, $modal) {
  var self = this;

  $.ajax({
    url: AS.app_prefix("top_containers/bulk_operations/update"),
    data: $form.serializeArray(),
    type: "post",
    success: function(html) {
      $form.replaceWith(html);
      $modal.trigger("resize.modal");
    },
    error: function(jqXHR, textStatus, errorThrown) {
      var error = AS.renderTemplate("template_bulk_operation_error_message", {message: jqXHR.responseText});
      $('#alertBucket').replaceWith(error);
    }
  });
};

BulkActionLocationUpdate.prototype.setup_menu_item = function() {
  var self = this;

  self.$menuItem = $("#" + self.MENU_ID, self.bulkContainerSearch.$toolbar);

  self.$menuItem.on("click", function(event) {
    self.show();
  });
};


BulkActionLocationUpdate.prototype.show = function() {
  var dialog_content = AS.renderTemplate("bulk_action_update_location", {
    selection: this.bulkContainerSearch.get_selection()
  });

  var $modal = AS.openCustomModal("bulkUpdateModal", this.$menuItem[0].text, dialog_content, 'full');

  this.setup_update_form($modal);
};


/***************************************************************************
 * BulkActionMultipleLocationUpdate - Multiple Location bulk action
 *
 */
function BulkActionMultipleLocationUpdate(bulkContainerSearch) {
  this.bulkContainerSearch = bulkContainerSearch;
  this.MENU_ID = "bulkActionUpdateMultipleLocation";

  this.setup_menu_item();
};


BulkActionMultipleLocationUpdate.prototype.setup_update_form = function($modal) {
  var self = this;

  var $form = $modal.find("form");

  $(document).trigger("loadedrecordsubforms.aspace", [$form]);

  $form.ajaxForm({
    dataType: "html",
    type: "POST",
    beforeSubmit: function() {
      $form.find(":submit").addClass("disabled").attr("disabled","disabled");
      $form.find(".error").removeClass("error");
    },
    success: function(html) {
      $form.replaceWith(html);
      $modal.trigger("resize.modal");
    },
    error: function(jqXHR, textStatus, errorThrown) {
      var error = $("<div>").attr("id", "alertBucket").html(jqXHR.responseText);
      $('#alertBucket').replaceWith(error);
      var uri = $('.alert-danger:first', '#alertBucket').data("uri");
      if (uri) {
        $(":input[value='"+uri+"']", $form).closest("td").addClass("form-group").addClass("error");
      }
      $form.find(":submit").removeClass("disabled").removeAttr("disabled");
    }
  });
};


BulkActionMultipleLocationUpdate.prototype.setup_menu_item = function() {
  var self = this;

  self.$menuItem = $("#" + self.MENU_ID, self.bulkContainerSearch.$toolbar);

  self.$menuItem.on("click", function(event) {
    self.show();
  });
};


BulkActionMultipleLocationUpdate.prototype.show = function() {
  var dialog_content = AS.renderTemplate("bulk_action_update_location_multiple", {
    selection: this.bulkContainerSearch.get_selection()
  });

  var $modal = AS.openCustomModal("bulkUpdateModal", this.$menuItem[0].text, dialog_content, 'full');

  this.setup_update_form($modal);
};


/***************************************************************************
 * BulkActionBarcodeRapidEntry - bulk action for barcode rapid entry
 *
 */

function BulkActionBarcodeRapidEntry(bulkContainerSearch) {
  this.TEMPLATE_DIALOG_ID = "template_bulk_barcode_action_dialog";
  this.MENU_ID = "showBulkActionRapidBarcodeEntry";

  this.bulkContainerSearch = bulkContainerSearch;

  this.setup_menu_item();
}


BulkActionBarcodeRapidEntry.prototype.setup_menu_item = function() {
  var self = this;

  self.$menuItem = $("#" + self.MENU_ID, self.bulkContainerSearch.$toolbar);

  self.$menuItem.on("click", function(event) {
    self.show();
  });
};


BulkActionBarcodeRapidEntry.prototype.show = function() {
  var dialog_content = AS.renderTemplate(this.TEMPLATE_DIALOG_ID, {
    selection: this.bulkContainerSearch.get_selection()
  });
  var $modal = AS.openCustomModal("bulkActionBarcodeRapidEntryModal", this.$menuItem[0].text, dialog_content, "full");

  this.setup_keyboard_handling($modal);
  this.setup_form_submission($modal);
};


BulkActionBarcodeRapidEntry.prototype.setup_keyboard_handling = function($modal) {
  $modal.find("table :input:visible:first").focus().select();

  $(":input", $modal).
    on("focus",
    function() {
      $.scrollTo($(this), 0, {
        offset: {
          top: 400
        }
      });
    }).
    on("keypress",
    function(event) {
      if (event.keyCode == 13) {
        event.stopPropagation();
        event.preventDefault();

        $(":input", $(this).closest("tr").next()).focus().select();
        return false;
      }
    }
  );
};


BulkActionBarcodeRapidEntry.prototype.setup_form_submission = function($modal) {
  var self = this;
  var $form = $modal.find("form");

  $form.ajaxForm({
    dataType: "html",
    type: "POST",
    beforeSubmit: function() {
      $form.find(":submit").addClass("disabled").attr("disabled","disabled");
      $form.find(".error").removeClass("error");
    },
    success: function(html) {
      $form.replaceWith(html);
      $modal.trigger("resize.modal");
    },
    error: function(jqXHR, textStatus, errorThrown) {
      var error = $("<div>").attr("id", "alertBucket").html(jqXHR.responseText);
      $('#alertBucket').replaceWith(error);
      var uri = $('.alert-danger:first', '#alertBucket').data("uri");
      if (uri) {
        $(":input[value='"+uri+"']", $form).closest("td").addClass("form-group").addClass("error");
      }
      $form.find(":submit").removeClass("disabled").removeAttr("disabled");
    }
  });
};


/***************************************************************************
 * BulkActionMerge - bulk action for merge
 *
 */

function activateBtn(event) {
  var merge_btn = document.getElementsByClassName("merge-button")[0];
  if ($('input:checked').length > 0) {
    merge_btn.removeAttribute("disabled");
  } else {
    merge_btn.attr("disabled", "disabled");
  };
 };

function BulkActionMerge(bulkContainerSearch) {
  var self = this;

  self.bulkContainerSearch = bulkContainerSearch;

  var $link = $("#bulkActionMerge", self.bulkContainerSearch.$toolbar);

  $link.on("click", function() {
    AS.openCustomModal("bulkMergeModal", "Merge Top Containers", AS.renderTemplate("bulk_action_merge", {
      selection: self.bulkContainerSearch.get_selection()
    }), 'full');

    // Access modal1 DOM
    const $mergeBtn = $("[data-js='merge']");

    $mergeBtn.on("click", function(e) {
      e.preventDefault();

      // Set up data for form submission
      const victims = self.bulkContainerSearch
                          .get_selection()
                          .map(function(container) {
                            return {
                              uri: container.uri,
                              display_string: container.display_string
                            }
                          });

      const targetEl = document.querySelector('input[name="target[]"]:checked');

      const target = {
        display_string: targetEl.getAttribute('aria-label'),
        uri: targetEl.getAttribute('value')
      };

      // compute victims list for template rendering
      const victimsNoTarget = victims.reduce(function(acc, victim) {
        if (victim.display_string !== target.display_string) {
          acc.push(victim.display_string);
        }
        return acc;
      }, [])

      // Init modal2
      AS.openCustomModal("bulkMergeConfirmModal", "Confirm Merge Top Containers", AS.renderTemplate("bulk_action_merge_confirm", {
        victims,
        victimsNoTarget,
        target
      }), false);
    })

  });
};


/***************************************************************************
 * BulkActionDelete - bulk action for delete
 *
 */
function BulkActionDelete(bulkContainerSearch) {
  var self = this;

  self.bulkContainerSearch = bulkContainerSearch;

  var $link = $("#bulkActionDelete", self.bulkContainerSearch.$toolbar);

  $link.on("click", function() {
    AS.openCustomModal("bulkActionModal", "Delete Top Containers", AS.renderTemplate("bulk_action_delete", {
      selection: self.bulkContainerSearch.get_selection()
    }), 'full');
  });
}


/***************************************************************************
 * Initialise all special features on this page
 *
 */
$(function() {

  var bulkContainerSearch = new BulkContainerSearch(
                                                  $("#bulk_operation_form"),
                                                  $("#bulk_operation_results"),
                                                  $(".record-toolbar.bulk-operation-toolbar"));

  new BulkActionBarcodeRapidEntry(bulkContainerSearch);
  new BulkActionIlsHoldingUpdate(bulkContainerSearch);
  new BulkActionContainerProfileUpdate(bulkContainerSearch);
  new BulkActionLocationUpdate(bulkContainerSearch);
  new BulkActionMultipleLocationUpdate(bulkContainerSearch);
  new BulkActionMerge(bulkContainerSearch);
  new BulkActionDelete(bulkContainerSearch);
});
