describe('SearchToolbarView', function() {

  beforeEach(function(done) {
    affix("#search-box");
    var $container = affix("#search-toolbar-tmpl");
    $container.affix("div#editor-container");
    $container.affix("a#search-button");
    var $a = $container.affix("ul#numberresults").affix('li').affix("a");
    $a.text('1000');

    $container.affix("ul#sortorder").affix('li[data-value="bar"]').affix("a");

    $(function() {
      done();
    });

  });


  it("emits a changepagesize.aspace event when $('#numberresults a') elements are clicked", function() {
    var searchToolbarView = new app.SearchToolbarView({
        query: {}
      });
    var eventTriggered = false;
    var resultsPerPage = 10;

    searchToolbarView.on("changepagesize.aspace", function(newSize) {
      eventTriggered = true;
      resultsPerPage = newSize;
    });

    $("#numberresults a").trigger("click");

    expect(eventTriggered).toEqual(true);
    expect(resultsPerPage).toEqual(1000);
  });


  it("emits a changesortorder.aspace event when $('#sortorder a') elements are clicked", function() {
    var searchToolbarView = new app.SearchToolbarView({
        query: {}
      });
    var eventTriggered = false;
    var sortOrder = 'foo';

    searchToolbarView.on("changesortorder.aspace", function(newSortOrder) {
      eventTriggered = true;
      sortOrder = newSortOrder;
    });

    $("#sortorder a").trigger("click");

    expect(eventTriggered).toEqual(true);
    expect(sortOrder).toEqual('bar');
  });



  it("updates the query and emits a modifiedquery.aspace event when $('#search-button') is clicked", function(done) {
    var mockQuery = jasmine.createSpyObj('query', ['updateCriteria', 'buildQueryString', 'foo']);
    var mockSearchEditor = jasmine.createSpyObj('searchEditor', ['extract']);

    var searchToolbarView = new app.SearchToolbarView({
      query: mockQuery
    });

    searchToolbarView.searchEditor = mockSearchEditor;

    expect(mockSearchEditor.extract).not.toHaveBeenCalled();
    expect(mockQuery.updateCriteria).not.toHaveBeenCalled();

    searchToolbarView.on("modifiedquery.aspace", function(query) {
      expect(mockSearchEditor.extract).toHaveBeenCalled();
      expect(mockQuery.updateCriteria).toHaveBeenCalled();
      expect(query.foo).toBeDefined(); //ensure we got the right object
      done();
    });

    $("#search-button").trigger("click");
  });


});
