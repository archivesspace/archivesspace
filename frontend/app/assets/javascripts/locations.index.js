//= require search
$(function() {

  // this gets the location information from the solr backend.
  // borrowed from the embedded_search js
  var init_locationHoldingsSearch = function() {
    var $this = $(this);
    if ($(this).data("initialised")) return;

    $this.data("initialised", true);
   
    var resultsFormatter = function(json) {
     console.log(json); 
      return ;
    }
   
    $.getJSON($this.data('url'), function(json) {
      var output; 
      itemCount = json["search_data"]["total_hits"];
      if ( itemCount == 1 ) { 
          output = "1 top container."; 
       } else if (itemCount > 0 ) {
        output = itemCount + " top containers.";  
      } else {
        output = "No holdings for this repository.";  
      } 
      $this.html("<span>" + output + "</span>"); 
    });
              
  };

  $(".location-holdings").each(init_locationHoldingsSearch);
  $(document).bind("loadedrecordform.aspace", function(event, $container) {
    $(".location-holdings", $container).each(init_locationHoldingsSearch);
  });

});
