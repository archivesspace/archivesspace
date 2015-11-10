describe('Search Results', function() {

  beforeEach(function() {
    jasmine.Ajax.install();
  })


  beforeEach(function() {
    this.searchResults = new SearchResults([], {
      queryParams: {
        q: 'foo'
      }
    });

    this.searchResults.fetch();
    this.request = jasmine.Ajax.requests.mostRecent();
  });


  beforeEach(function() {
    this.request.respondWith(TestResponses.search.success);
  });


  afterEach(function() {
    jasmine.Ajax.uninstall();
  });


  it('can say how many results it has', function() {
    console.log(this.searchResults.state);
    expect(this.searchResults.state.totalRecords).toEqual(3);
  });

});
