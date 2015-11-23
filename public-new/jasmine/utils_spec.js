describe('Utils', function() {

  it("can parse a query string into search params", function() {
    var queryString = 'page=1&filter_term%5B%5D=%7B"repository":"/repositories/2"%7D&filter_term%5B%5D=%7B"subjects":"Papers"%7D';

    var parsed = app.utils.parseQueryString(queryString);

    console.log(parsed);
    expect(parsed["filter_term[]"][0]).toEqual('{"repository":"/repositories/2"}');
    expect(parsed["filter_term[]"][1]).toEqual('{"subjects":"Papers"}');

  });

});
