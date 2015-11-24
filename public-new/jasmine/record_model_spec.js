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

    this.resourceRecord.fetch();

    this.request = jasmine.Ajax.requests.mostRecent();
    this.request.respondWith(TestResponses.resource.success);
  });


  afterEach(function() {
    jasmine.Ajax.uninstall();
  });


  it('fetches data from the server', function() {
    expect(this.request.url).toEqual('/api/repositories/2/resources/1');
    expect(this.resourceRecord.attributes.title).toEqual("Dick Cavett Papers");
  });
});
