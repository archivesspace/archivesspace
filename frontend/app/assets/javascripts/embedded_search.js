$(function() {

  var init_embeddedSearch = function() {
    var $this = $(this);
    if ($(this).data("initialised")) return;

    $this.data("initialised", true);

    $this.on("click", "a", function(event) {
      if ($(this).closest(".table-record-actions").length > 0) {
        return;
      }

      event.preventDefault();

      loadSearchResults(event.target.href);
    });

    var loadSearchResults = function(url) {
      $this.load(url, function(html) {
        $this.html(html);
      });
    };

    loadSearchResults($this.data("url"));
  };

  $(".embedded-search").each(init_embeddedSearch);
  $(document).bind("loadedrecordform.aspace", function(event, $container) {
    $(".embedded-search", $container).each(init_embeddedSearch);
  });

});