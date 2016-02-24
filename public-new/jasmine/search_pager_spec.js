describe('SearchPagerView', function() {

  beforeEach(function(done) {
    $(function() {
      done();
    });

  });


  it("calls its template with a helper object for building pagination links", function() {

    var tmplSpy = spyOn(app.utils, 'tmpl').and.returnValue();
    var query = {
      page: 2,
      buildQueryString: function(args) {
        return "/searchme?foo=bar";
      }
    };

    var buildQueryStringSpy = spyOn(query, 'buildQueryString').and.callThrough();

    var opts = {
      query: query,
      resultsState: {
        currentPage: 2,
        totalPages: 3
      }
    };

    var searchPagerView = new app.SearchPagerView(opts);
    expect(app.utils.tmpl.calls.argsFor(0)[0]).toEqual('search-pager')
    var pagerHelper = app.utils.tmpl.calls.argsFor(0)[1];
    expect(pagerHelper.hasPreviousPage).toEqual(true);
    expect(pagerHelper.hasNextPage).toEqual(true);
    expect(pagerHelper.getPagerEnd()).toEqual(3);
    expect(pagerHelper.getPagerStart()).toEqual(1);

    pagerHelper.getPreviousPageURL();
    expect(buildQueryStringSpy).toHaveBeenCalledWith({page: 1});

    pagerHelper.getNextPageURL();
    expect(buildQueryStringSpy).toHaveBeenCalledWith({page: 3});

  });

});
