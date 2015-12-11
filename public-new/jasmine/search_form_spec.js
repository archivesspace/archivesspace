describe('Search Form', function() {

  beforeEach(function(done) {
    jasmine.getFixtures().fixturesPath = 'base/jasmine/fixtures';
    loadFixtures("layout.html");

    jasmine.Ajax.install();

    $(function() {
      done();
    });

  });


  afterEach(function() {
    jasmine.Ajax.uninstall();
  });


  it("captures the 'click' event in $('#search-form') and serializes $('input') and $('li.selected') to navigate to the correct search url", function() {
    var routerSpy = spyOn(app.router, 'navigate').and.returnValue(true);
 
    var searchBoxView = new app.SearchBoxView();
    expect($('#search-form')).toBeInDOM();

    $("#search-button").click();

    expect(routerSpy).toHaveBeenCalledWith('/search?', {trigger: true});

    // now tweak the form DOM a bit
    $("#search-form").append("<input name='foo' value='bar' />");
    _.forEach([0,1], function(i) {
      $("#search-form").append("<ul id='beep"+i+"'><li data-value='boop"+i+"' class='selected'>whatev</li></ul>");
    });

    $("#search-button").click();

    expect(routerSpy).toHaveBeenCalledWith('/search?foo=bar&beep0=boop0&beep1=boop1', {trigger: true});
  });


});
