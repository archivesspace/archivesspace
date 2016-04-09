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
        currentPage: 1,
        query: [{
          field: "title",
          recordtype: "any",
          value: "big"
        }, {
          field: "keyword",
          op: "OR",
          value: "paper"
        }]
      }
    });

    this.searchResults.fetch({
      // don't really need this anymore - use applyFilter method.
      data: {
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
    expect(decoded).toContain('v0=big');
    expect(decoded).toContain('f0=title');
    expect(decoded).toContain('page_size=40');
    expect(decoded).toContain('page=1');
    expect(decoded).toContain('filter_term[]={"repositories":"/repositories/2"}');
  });

  it('can fetch a new page size', function(done) {
    this.searchResults.setPageSize(60);
    var request = jasmine.Ajax.requests.mostRecent();
    request.respondWith(TestResponses.search.success);
    expect(request.url).toContain('page_size=60');
    done();
  });


  it('can change sort order and re fetch', function(done) {
    this.searchResults.setSorting("title");
    this.searchResults.fetch();
    var request = jasmine.Ajax.requests.mostRecent();
    request.respondWith(TestResponses.search.success);
    console.log(request.url);
    expect(request.url).toContain('title_sort+asc');
    done();
  });


  it('can update the base query and refetch', function(done) {
    var newQuery = [{
      field: "title",
      recordtype: "any",
      value: "small"
    }, {
      field: "keyword",
      op: "OR",
      value: "paper"
    }];

    this.searchResults.updateQuery(newQuery);
    var request = jasmine.Ajax.requests.mostRecent();
    request.respondWith(TestResponses.search.success);
    expect(request.url).toContain('v0=small');
    done();
  });


  it('can apply multiple filters', function() {
    this.searchResults.applyFilter({'repositories': "/repositories/99"});
    this.searchResults.applyFilter({'repositories': "/repositories/98"});
    var request = jasmine.Ajax.requests.mostRecent();
    request.respondWith(TestResponses.search.success);
    var decoded = decodeURIComponent(request.url).replace(/.*\?/, '').split('&');
    expect(decoded).toContain('filter_term[]={"repositories":"/repositories/99"}');
    expect(decoded).toContain('filter_term[]={"repositories":"/repositories/98"}');
  });


  it('can remove a filter', function() {
    this.searchResults.applyFilter({'repositories': "/repositories/99"});
    var request = jasmine.Ajax.requests.mostRecent();
    request.respondWith(TestResponses.search.success);
    var decoded = decodeURIComponent(request.url).replace(/.*\?/, '').split('&');
    expect(decoded).toContain('filter_term[]={"repositories":"/repositories/99"}');

    this.searchResults.removeFilter({'repositories': "/repositories/99"});
    var request = jasmine.Ajax.requests.mostRecent();
    request.respondWith(TestResponses.search.success);
    var decoded = decodeURIComponent(request.url).replace(/.*\?/, '').split('&');
    expect(decoded).not.toContain('filter_term[]={"repositories":"/repositories/99"}');
  });


  it('knows how many results it has', function() {
    expect(this.searchResults.state.totalRecords).toEqual(3);
  });


  describe('Identifier searchers', function() {

    it('wraps quotes around an identifier query if it has whitespace', function() {
      var idQuery = [{
        field: "identifier",
        recordtype: "any",
        value: "SS Minow"
      }];

      this.searchResults.updateQuery(idQuery)
      var request = jasmine.Ajax.requests.mostRecent();
      request.respondWith(TestResponses.search.success);
      expect(request.url).toContain('v0=%22SS+Minow%22');

    });

    it('bookends an id query with wildcard if it seems like the user intended to search an identifier segment', function() {
      var idQuery = [{
        field: "identifier",
        recordtype: "any",
        value: "SS"
      }];

      this.searchResults.updateQuery(idQuery)
      var request = jasmine.Ajax.requests.mostRecent();
      request.respondWith(TestResponses.search.success);
      expect(request.url).toContain('v0=*SS*');
    });
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
