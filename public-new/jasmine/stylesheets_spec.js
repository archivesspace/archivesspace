// require quixote

var frame;

var dtiOrig = jasmine.DEFAULT_TIMEOUT_INTERVAL;
jasmine.DEFAULT_TIMEOUT_INTERVAL = 10000;

describe('stylesheets', function() {

  beforeAll(function(done) {
    frame = quixote.createFrame({
      stylesheet: '/base/app/assets/stylesheets/application.css'
    });

    setTimeout(function() {
      done();
    }, 5000);

  });

  afterAll(function() {
    frame.remove();
    jasmine.DEFAULT_TIMEOUT_INTERVAL = dtiOrig;
  });

  beforeEach(function() {
    frame.reset();
  });


  it("makes <h1> elements darkblue", function(done) {
    var DARKBLUE = "rgb(5, 83, 138)";

    frame.add("<h1 id='foo'>FOO</h1>");

    header = frame.get("#foo");

    expect(header.getRawStyle("color")).toEqual(DARKBLUE);

    done();
  });


  describe("Search Editor rows", function() {

    beforeEach(function() {
      frame.add("<div class='search-query-row'><button type='button' class='button'>Foo</div>");
    });


    it("has 500 weight button text", function(done) {

      button = frame.get(".button");

      expect(button.getRawStyle("font-weight")).toEqual('500');

      done();
    });

  });


  describe("record type badges", function() {

    beforeEach(function() {
      frame.add("<div class='record-type-badge resource'><i class='fi-torso'></i>&#160;Resource</div>");
    });

    it("gives a 1 px border to record badges", function(done) {
      badge = frame.get(".record-type-badge");
      expect(badge.getRawStyle("border-top-width")).toEqual('1px');
      expect(badge.getRawStyle("font-family")).toEqual('"Roboto Slab",serif');

      done();
    });

  });

})
