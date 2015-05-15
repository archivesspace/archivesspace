$(function() {

  // this gets the location information from the solr backend.
  // borrowed from the embedded_search js
  var init_enumValueSearch = function() {
    var $this = $(this);
    if ($(this).data("initialised")) return;

    $this.data("initialised", true);
   
    var resultsFormatter = function(json) {
     console.log(json); 
      return ;
    }
   
    $.getJSON($this.data('url'), function(json) {
      var output;
      var url = $this.data('url');
      itemCount = json["search_data"]["total_hits"];
      if ( itemCount == 1 ) { 
        output = "1 related item."; 
       } else if (itemCount > 0 ) {
        output = itemCount + " related items.";  
      } else {
        $this.closest('tr').find('.btn-info').attr('disabled', false) 
        output = "Not used.";  
      } 
      $this.html("<a href='" + url + "'>" + output + "</a>"); 
    });
              
  };
  
  $(".enum-value-search").each(init_enumValueSearch);

  var handleEnumNameChange = function(event) {
    document.location.search = "?id="+$(this).val()
  };

  $("#enum_selector").change(handleEnumNameChange);

});
