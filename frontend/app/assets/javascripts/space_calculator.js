//= require linker
//= require tablesorter/jquery.tablesorter.min

function SpaceCalculatorForContainerLocation($container) {
  this.$btn = $container.find(".show-space-calculator-btn");
  this.$linkerWrapper = this.$btn.closest(".linker-wrapper");
  this.$linker = this.$linkerWrapper.find(".linker");

  this.setupEvents();
}

SpaceCalculatorForContainerLocation.prototype.setupEvents = function() {
  var self = this;

  self.$btn.on("click", function(event) {
    new SpaceCalculatorModal({
      modalInitialContent: self.$btn.data("modal-content"),
      url: self.$btn.data("calculator-url"),
      selectable: true,
      containerProfile: self.getContainerProfileURI(),
      onSelect: function($results) {
        $(".token-input-delete-token", self.$linkerWrapper).each(function() {
          $(this).triggerHandler("click");
        });

        var $selected = $results.find("#tabledSearchResults :input:checked:first");
        var locationJSON = $selected.data("object")._resolved;

        self.$linker.tokenInput("add", {
          id: $selected.val(),
          name: locationJSON.title,
          json: locationJSON
        });

        self.$linker.triggerHandler("change");
      }
    });
  });
};

SpaceCalculatorForContainerLocation.prototype.getContainerProfileURI = function() {
  return $(document).find("[name='top_container[container_profile][ref]']").val();
};


function SpaceCalculatorForButton($btn) {
  $btn.on("click", function(event) {
    event.preventDefault();

    new SpaceCalculatorModal({
      modalInitialContent: $btn.data("modal-content"),
      url: $btn.data("calculator-url"),
      selectable: $btn.data("selectable"),
      containerProfile: $btn.data("container-profile-uri")
    });
  });
};


function SpaceCalculatorModal(options) {
  var self = this;

  self.options = options;

  self.$modal = AS.openCustomModal("spaceCalculatorModal",
                                   null,
                                   "<div class='alert alert-info'>"+self.options.modalInitialContent+"</div>",
                                   "large", {}, this);

  $.ajax({
    url: self.options.url,
    type: "GET",
    data: {
      container_profile_ref: self.options.containerProfile,
      selectable: self.options.selectable
    },
    success: function (html) {
      $(".alert", self.$modal).replaceWith(html);
      self.setupForm(self.$modal.find("form"));
      $(window).trigger("resize");
    },
    error: function(jqXHR, textStatus, errorThrown) {
      $(".alert", self.$modal).replaceWith(AS.renderTemplate("modal_quick_template", {message: jqXHR.responseText}));
      $(window).trigger("resize");
    }
  });
}

SpaceCalculatorModal.prototype.setupForm = function($form) {
  var self = this;

  self.$results = self.$modal.find("#spaceCalculatorResults");

  self.$modal.find(".linker").linker();

  self.setupByBuildingSearch();

  self.$modal.find("#addSelectedButton").attr("disabled","disabled");

  $form.ajaxForm({
    beforeSubmit: function() {
      self.$modal.find("#addSelectedButton").attr("disabled","disabled");
      self.$results.html(AS.renderTemplate("spaceCalculatorLoadingTemplate"));
    },
    success: function(html) {
      self.$modal.find("#spaceCalculatorResults").html(html);
      self.setupResults();
      self.setupResultsFilter();
      self.setupResultsToggles();
    }
  });

  self.$modal.find("#byBuilding").on("hide.bs.collapse", function() {
    self.$modal.find("#byBuilding :input").prop("disabled", true);
  }).on("show.bs.collapse", function() {
    self.$modal.find("#byBuilding :input").prop("disabled", false);
  });

  self.$modal.find("#byLocation").on("hide.bs.collapse", function() {
    self.$modal.find("#byLocation :input").prop("disabled", true);
    }).on("show.bs.collapse", function() {
    self.$modal.find("#byLocation :input").prop("disabled", false);
    });
};

SpaceCalculatorModal.prototype.setupByBuildingSearch = function() {
  var self = this;

  var $building = self.$modal.find("#building");
  var $floor = self.$modal.find("#floor");
  var $room = self.$modal.find("#room");
  var $area = self.$modal.find("#area");

  $building.on("change", function() {
    $floor.val("").closest(".form-group").hide();
    $room.val("").closest(".form-group").hide();
    $area.val("").closest(".form-group").hide();
    if ($building.val() != "") {
      var floors = AS.building_data[$building.val()];
      if (!$.isEmptyObject(floors)) {
        $floor.empty();
        $floor.append($("<option>"));
        for (var floor in floors) {
          $floor.append($("<option>").html(floor));
        }
        $floor.closest(".form-group").show();
      }
    }
  });

  $floor.on("change", function() {
    $room.val("").closest(".form-group").hide();
    $area.val("").closest(".form-group").hide();
    if ($floor.val() != "") {
      var rooms = AS.building_data[$building.val()][$floor.val()];
      if (!$.isEmptyObject(rooms)) {
        $room.empty();
        $room.append($("<option>"));
        for (var room in rooms) {
          $room.append($("<option>").html(room));
        }
        $room.closest(".form-group").show();
      }
    }
  });

  $room.on("change", function() {
    $area.val("").closest(".form-group").hide();
    if ($room.val() != "") {
      var areas = AS.building_data[$building.val()][$floor.val()][$room.val()];
      if (areas != null && areas.length > 0) {
        $area.empty();
        $area.append($("<option>"));
        for (var i=0; i<areas.length; i++) {
          $area.append($("<option>").html(areas[i]));
        }
        $area.closest(".form-group").show();
      }
    }
  });

};

SpaceCalculatorModal.prototype.setupResults = function() {
  var self = this;

  $(":input[name=linker-item]", self.$results).each(function() {
    var $input = $(this);

    $input.click(function(event) {
      event.stopPropagation();

      $("tr.selected", $input.closest("table")).removeClass("selected");
      $input.closest("tr").addClass("selected");
      self.$modal.find("#addSelectedButton").removeAttr("disabled");
    });

    $("td", $input.closest("tr")).click(function(event) {
      event.preventDefault();

      $input.trigger("click");
    });
  });

  self.$modal.on("click","#addSelectedButton", function(event) {
    self.options.onSelect && self.options.onSelect(self.$results);
    self.$modal.modal('hide');
  });

  var $table = self.$results.find("#tabledSearchResults");

  var $headers = $table.find("thead tr:first");

  var TABLE_SORTER_OPTS = {
    // default sort: Space?, Location, Count
    sortList: [
      [$headers.find(".space").index(),0],
      [$headers.find(".count").index(),1]
    ],
    // customise text extraction for the icon and count column
    textExtraction: function(cell) {
      var $cell = $(cell);

      if ($cell.hasClass("space")) {
        return $cell.hasClass("success") ? 0 : 1;
      } else if ($cell.hasClass("count")) {
        return $cell.data("count");
      }

      return $cell.text().trim();
    }
  };

  if (self.$results.find(".col.selectable:first")) {
    // disable sorting of checkbox column
    TABLE_SORTER_OPTS["header"] = {
      "0": false
    }
  }

  $table.tablesorter(TABLE_SORTER_OPTS);
};

SpaceCalculatorModal.prototype.setupResultsFilter = function() {
  var self = this;
  var $input = self.$results.find("#searchResultsFilter");
  var searchTimeout;

  function performSearch() {
    // split on words and retain quoted groups of terms
    var keywords = $input.val().match(/\w+|"[^"]+"/g) || [];

    self.$results.find("#tabledSearchResults tbody tr").each(function() {

      var $tr = $(this);

      var text = $tr.text();

      var match = true;
      for (var i=0; i<keywords.length; i++) {
        // remove extra quotes from the filter term
        var keyword = keywords[i].replace(/\"/g, "");
        if (keyword === "") {
          continue;
        }
        if (!(new RegExp(keyword, "i")).test(text)) {
          match = false;
          break;
        }
      }

      if (match) {
        $tr.removeClass("filtered-by-search");
      } else {
        $tr.addClass("filtered-by-search");
      }
    });
  };

  $input.on("keyup", function() {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(performSearch, 200);
  });
};

SpaceCalculatorModal.prototype.setupResultsToggles = function() {
  var self = this;
  var $toggles = self.$results.find(".space-calculator-results-toggle");

  $toggles.each(function() {
    var $toggle = $(this);

    if ($toggle.is(":disabled")) {
      $toggle.closest(".btn").addClass("disabled");
    }
  });


  $toggles.on("click", function() {
    var $toggle = $(this);
    var $targetResults = self.$results.find($toggle.data("target-selector"));

    if ($toggle.is(":checked")) {
      $targetResults.removeClass("filtered-by-toggle");
    } else {
      $targetResults.addClass("filtered-by-toggle");
    }
  });
};

$(document).bind("subrecordcreated.aspace", function(event, object_name, subform) {
  if (object_name == "container_location") {
    new SpaceCalculatorForContainerLocation(subform);
  }
});