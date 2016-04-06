describe('RecordContainerView', function() {

  function FonyRecordModel(opts) {}

  FonyRecordModel.prototype.fetch = function() {
    this.attributes = {
      repository: {
        ref: "/what/the/foo",
        _resolved: {
          name: "What the FOO Repository",
          agent_representation: {
            _resolved: {
              agent_contacts: [{
                address_1: "1 yale lane",
                address_2: "apt 2",
                city: "yale city",
                create_time: "2016-01-27T04:23:11Z",
                created_by: "admin",
                email: "foo@bar.com",
                jsonmodel_type: "agent_contact",
                last_modified_by: "admin",
                lock_version: 0,
                name: "Yale University Special Collections",
                region: "CT",
                system_mtime: "2016-01-27T04:23:11Z",
                telephones: [{
                  create_time: "2016-01-27T04:23:12Z",
                  created_by: "admin",
                  jsonmodel_type: "telephone",
                  last_modified_by: "admin",
                  number: "555-1234",
                  number_type: "business",
                  system_mtime: "2016-01-27T04:23:12Z",
                  uri: "/telephone/1",
                  user_mtime: "2016-01-27T04:23:12Z",
                  user_mtime: "2016-01-27T04:23:11Z",
                }]
              }]
            }
          }
        }
      }
    };
    var d = $.Deferred();
    d.resolve(true);
    return d;
  };


  beforeEach(function(done) {
    app.RecordModel = FonyRecordModel;

    affix("#container");
    affix("#wait-modal[class='reveal'][data-reveal]")
    var $tmpl = affix("#record-tmpl");

    $(function() {
      $(document).foundation();
      done();
    });
  });

  it("passes a presenter object to the container", function() {
    var tmplSpy = spyOn(app.utils, 'tmpl').and.returnValue();

    var recordContainerView = new app.RecordContainerView({what: 'ever'});

    expect(app.utils.tmpl.calls.argsFor(0)[0]).toEqual('record')
    var presenter = app.utils.tmpl.calls.argsFor(0)[1];

    expect(presenter.repository.name).toContain('What the FOO Repository');
    expect(presenter.repository.phone).toEqual("555-1234");
    expect(presenter.repository.address).toEqual("1 yale lane<br />apt 2<br />yale city");
    expect(presenter.repository.email).toEqual("foo@bar.com");

  });

});
