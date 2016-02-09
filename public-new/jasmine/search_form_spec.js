describe('SearchEditor', function() {

  beforeEach(function(done) {

    affix("#search-editor-container");
    affix("#search-query-row-tmpl").affix("div.add-query-row").affix("a");

    $(function() {
      done();
    });
  });


  it("can bind to a DOM container and add search query rows", function() {
    var $container = $("#search-editor-container");
    var editor = new app.SearchEditor($container);

    _.times(3, function() {
      editor.addRow();
    });

    expect($(".search-query-row", $container).length).toEqual(3);
  });

  it("can remove query rows and update the index accordingly", function() {
    var $container = $("#search-editor-container");
    var editor = new app.SearchEditor($container);

    _.times(3, function() {
      editor.addRow();
    });

    $(".remove-query-row a", $(".search-query-row").first()).trigger("click");
    expect($(".search-query-row", $container).length).toEqual(2);
  });
});
