describe('Search Results', function() {

  function splitURLParams(url) {
    var x= decodeURI(url).replace(/.*\?/, '').split('&');
    return(x);
  }

  beforeEach(function() {
    jasmine.Ajax.install();
  });

  beforeEach(function() {

    this.searchResults = new app.SearchResults([], {
      state: {
        pageSize: 40,
        currentPage: 1
      }
    });

    this.searchResults.fetch({
      data: {
        q: 'foo',
        filter_term: ['{"repositories":"/repositories/2"}'],
      }
    });
    this.request = jasmine.Ajax.requests.mostRecent();
  });


  beforeEach(function() {
    this.request.respondWith(TestResponses.search.success);
  });


  afterEach(function() {
    jasmine.Ajax.uninstall();
  });


  it('translates query params for the server', function() {
    expect(this.request.url).toMatch(/^\/api\/search/);
    var decoded = decodeURIComponent(this.request.url).replace(/.*\?/, '').split('&');
    expect(decoded).toContain('q=foo');
    expect(decoded).toContain('page_size=40');
    expect(decoded).toContain('page=1');
    expect(decoded).toContain('filter_term[]={"repositories":"/repositories/2"}');
  });

  it('knows how many results it has', function() {
    expect(this.searchResults.state.totalRecords).toEqual(3);
  });

  it('can create filtering and pagination links with current criteria', function() {
    var biggerPageURL = this.searchResults.getPageSizeURL(200);
    var nextPageURL = this.searchResults.getNextPageURL();
    var anotherFilterURL = this.searchResults.getAddFilterURL('{"subjects":"parties"}');
    var removeFilterURL = this.searchResults.getRemoveFilterURL('{"repositories":"/repositories/2"}');

    _.each([biggerPageURL, nextPageURL, anotherFilterURL], function(URL) {
      var decoded = splitURLParams(URL);
      expect(decoded).toContain('q=foo');
      expect(decoded).toContain('filter_term[]={"repositories":"/repositories/2"}');
    });

    expect(splitURLParams(anotherFilterURL)).toContain('pageSize=40');
    expect(splitURLParams(biggerPageURL)).toContain('pageSize=200');
    expect(splitURLParams(biggerPageURL)).not.toContain('pageSize=40');

    expect(splitURLParams(removeFilterURL)).not.toContain('filter_term[]={"repositories":"/repositories/2"}');
    expect(splitURLParams(removeFilterURL)).toContain('pageSize=40');
  });


  describe('SearchResultItem', function() {

    beforeEach(function() {
      this.item = this.searchResults.models[0];
    });

    it('stores the record title in the attributes object', function() {
      expect(this.item.attributes.title).toEqual("Jimmy Page Papers");
    });

    it('generates a public-friendly url for resource records', function() {
      expect(this.item.getURL()).toEqual('/repositories/13/collections/666');
    });


  });


});
