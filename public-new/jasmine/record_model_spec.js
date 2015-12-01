describe('Record Model(s)', function() {

  beforeEach(function() {
    jasmine.Ajax.install();
  });

  beforeEach(function() {
    this.resourceRecord = new app.RecordModel({
      type: 'resource',
      id: 1,
      repo_id: 2
    });

    this.resourceRecord.fetch({
      error: function(model, response, options) {
        model.barf = true;
      }
    });

    this.request = jasmine.Ajax.requests.mostRecent();
  });


  afterEach(function() {
    jasmine.Ajax.uninstall();
  });


  describe('fetching: happy path', function() {

    beforeEach(function() {
      this.request.respondWith(TestResponses.resource.success);
    });

    it('fetches data from the server', function() {
      expect(this.request.url).toEqual('/api/repositories/2/resources/1');
      expect(this.resourceRecord.attributes.title).toEqual("Dick Cavett Papers");
    });
  });

  describe('fetching: tragic path', function() {

    beforeEach(function() {
      this.request.respondWith(TestResponses.resource.failure);
    });

    it('accepts an error handling callback', function() {
      expect(this.request.url).toEqual('/api/repositories/2/resources/1');
      console.log(this.resourceRecord);
      expect(this.resourceRecord.barf).toEqual(true);
    });
  });

});
