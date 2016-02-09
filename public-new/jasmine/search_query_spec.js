describe('SearchQuery', function() {

  // it("can parse a query string into search params and translate them for the API", function() {
  //   var queryString = 'page=1&repository=/repositories/2&repository=/repositories/3&subject=Papers&subject=Rocks';

  //   var sq = new app.SearchQuery(queryString);
  //   var apiParams = sq.toApi();

  //   expect(apiParams["filter_term[]"][0]).toEqual('{"repository":"/repositories/2"}');
  //   expect(apiParams["filter_term[]"][1]).toEqual('{"repository":"/repositories/3"}');
  //   expect(apiParams["filter_term[]"][2]).toEqual('{"subjects":"Papers"}');
  //   expect(apiParams["filter_term[]"][3]).toEqual('{"subjects":"Rocks"}');

  // });


  // it("will ignore supernumerary page params", function() {
  //   var queryString = 'page=2&page=1&subject=rocks';

  //   var sq = new app.SearchQuery(queryString);

  //   expect(sq.page).toEqual(2);
  // });


});
