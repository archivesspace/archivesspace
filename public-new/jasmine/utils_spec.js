describe('Utils', function() {

  var advancedQuery = {
    query: {
      jsonmodel_type: "boolean_query",
      op: "OR",
      subqueries: [
        {
          field: "title",
          jsonmodel_type: "field_query",
          value: "objective"
        },
        {
          field: "title",
          jsonmodel_type: "field_query",
          value: "subjective"
        }
      ]
    }
  };


  var anotherQuery = {
    query: {
      field: "title",
      jsonmodel_type: "field_query",
      value: "rejective"
    }
  };


  it("can turn public app terminology into proper ASpace record type", function() {
    expect(app.utils.getASType('collection')).toEqual('resource');
    expect(app.utils.getASType('accession')).toEqual('accession');
  });

  it("can rename ASpace record type for the public app", function() {
    expect(app.utils.getPublicType('resource')).toEqual('collection');
    expect(app.utils.getPublicType('accession')).toEqual('accession');
  });

  it("can convert advanced query objects into url params", function() {

    var params = app.utils.convertAdvancedQuery(advancedQuery);

    expect(params.op1).toEqual("OR");
    expect(params.q0).toEqual("objective");
    expect(params.q1).toEqual("subjective");
    expect(params.f0).toEqual("title");
    expect(params.f1).toEqual("title");
  });

  it("can convert advanced query objects into flat arrays", function() {
    var list = app.utils.flattenAdvancedQuery(advancedQuery);

    expect(list).toEqual(["title:objective", "OR", "title:subjective"])
  });

  it("can iterate over advanced query as a set of rows", function() {
    var rowCount = 0
    app.utils.eachAdvancedQueryRow(advancedQuery, function(rowObj, i) {
      if(i === 0) {
        expect(rowObj.field).toEqual("title");
        expect(rowObj.value).toEqual("objective");
      } else {
        expect(rowObj.op).toEqual("OR");
        expect(rowObj.value).toEqual("subjective");
      }

      rowCount += 1;
    });

    expect(rowCount).toEqual(2);

    rowCount = 0;
    app.utils.eachAdvancedQueryRow(anotherQuery, function(rowObj, i) {
      expect(rowObj.field).toEqual("title");
      expect(rowObj.value).toEqual("rejective");
      expect(rowObj.op).toBeUndefined();

      rowCount += 1;
    });

    expect(rowCount).toEqual(1);

  });


});
