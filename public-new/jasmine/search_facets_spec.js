describe('SearchFacetsView', function() {

  function splitURLParams(url) {
    var x= decodeURI(url).replace(/.*\?/, '').split('&');
    return(x);
  }

  beforeEach(function(done) {
    affix("#sidebar");
    var $tmpl = affix("#facets-tmpl");

    $(function() {
      done();
    });

  });


  describe('FacetHelper', function() {

    beforeEach(function() {
      this.facetData = {
        "Repository":{"/repositories/3":{"label":"Ohio State University","count":28,"display_string":"Repository: /repositories/3","filter_term":"{\"repository\":\"/repositories/3\"}"}},
        "Type":{"archival_object":{"label":"Archival Object","count":27,"display_string":"Type: archival_object","filter_term":"{\"primary_type\":\"archival_object\"}"},"resource":{"label":"Collection","count":1,"display_string":"Type: resource","filter_term":"{\"primary_type\":\"resource\"}"}},
        "Subject":{"Costume designers -- United States -- 20th century":{"label":"Costume designers -- United States -- 20th century","count":1,"display_string":"Subject: Costume designers -- United States -- 20th century","filter_term":"{\"subjects\":\"Costume designers -- United States -- 20th century\"}"},"Costume designers -- United States -- 21st century":{"label":"Costume designers -- United States -- 21st century","count":1,"display_string":"Subject: Costume designers -- United States -- 21st century","filter_term":"{\"subjects\":\"Costume designers -- United States -- 21st century\"}"}},
        "Source":{},
        "Role":{}};
    });

    it('provides an iterator function for listing usable facet groups', function() {

      var helper = new app.SearchFacetsView.prototype.FacetHelper({
        facetData: this.facetData,
        totalRecords: 28
      });

      var groups = []

      helper.eachUsableFacetGroup(function(members, group) {
        groups.push(group);
      });

      expect(groups).toEqual(["Type", "Subject"]);

      helper = new app.SearchFacetsView.prototype.FacetHelper({
        facetData: this.facetData,
        totalRecords: 29
      });

      groups = []

      helper.eachUsableFacetGroup(function(members, group) {
        groups.push(group);
      });

      expect(groups).toEqual(["Repository", "Type", "Subject"]);
    });

  });


  it('can create filtering links with current criteria', function() {

    var state = {
      facetData: this.facetData,
      totalRecords: 28,
      pageSize: 40,
      facetData: {
        "Subject":{"Costume designers -- United States -- 20th century":{"label":"Costume designers -- United States -- 20th century","count":1,"display_string":"Subject: Costume designers -- United States -- 20th century","filter_term":"{\"subjects\":\"Costume designers -- United States -- 20th century\"}"},"Costume designers -- United States -- 21st century":{"label":"Costume designers -- United States -- 21st century","count":1,"display_string":"Subject: Costume designers -- United States -- 21st century","filter_term":"{\"subjects\":\"Costume designers -- United States -- 21st century\"}"}},
      },
      filters: [{"subjects": "all tomorrow's parties"}]
    }

    var helper = new app.SearchFacetsView.prototype.FacetHelper(state);

    var addSubjectFilterURL = splitURLParams(helper.getAddFilterURL("{\"subjects\":\"Costume designers -- United States -- 21st century\"}"));


    expect(addSubjectFilterURL).toContain("subjects=all tomorrow's parties");
    expect(addSubjectFilterURL).toContain('subjects=Costume designers -- United States -- 21st century');

    var addRepositoryFilterURL = splitURLParams(helper.getAddFilterURL('{"repository": "/repositories/69"}'));

    expect(addRepositoryFilterURL).toContain("repository=/repositories/69");

  });


});
