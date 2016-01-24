describe('Router', function() {

  var RecordModel404 = function(opts) {
    this.fetch = function() {
      var d = $.Deferred();
      d.reject({barf: true});
      return d;
    }
  }

  var RecordModel200 = function(opts) {
    this.fetch = function() {
      this.title = "Foo Record";
      var d = $.Deferred();
      d.resolve(true);
      return d;
    }
  }

  beforeEach(function() {
    jasmine.getFixtures().fixturesPath = 'base/jasmine/fixtures';
    loadFixtures("layout.html");

    jasmine.Ajax.install();
  });


  afterEach(function() {
    jasmine.Ajax.uninstall();
  });


  describe("showRecord", function() {

    beforeEach(function(done) {
      this.mockView = function(text) {
        return {
          $el: {
            html: function() {
              return "<h1>"+text+"</h1>";
            }
          }
        };
      };

      $(function() {
        $(document).foundation();
        done();
      });

    });

    // TODO - move to record model spec

    xit("instantiates a SeverErrorView when model fails", function(done) {
      var spy = spyOn(app, 'ServerErrorView').and.returnValue(
        this.mockView("BUMMER"));

      app.RecordModel = RecordModel404;
      app.router.showRecord({});
      expect(spy).toHaveBeenCalled();
      expect($('#main-content')).toContainHtml("<h1>BUMMER</h1>");
      done();
    });

    xit("instantiates a RecordView when the model loads", function(done) {
      var spy = spyOn(app, 'RecordView').and.returnValue(
        this.mockView("FAR OUT"));

      app.RecordModel = RecordModel200;
      app.router.showRecord({});
      expect(spy).toHaveBeenCalled();
      expect($('#main-content')).toContainHtml("<h1>FAR OUT</h1>");
      done();
    });

  });

});
