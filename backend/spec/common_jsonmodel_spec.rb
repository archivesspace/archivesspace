require 'spec_helper'

describe 'JSON model' do

  before(:all) do

    JSONModel.create_model_for("testschema",
                               {
                                 "type" => "object",
                                 "uri" => "/testthings",
                                 "properties" => {
                                   "elt_0" => {"type" => "string", "required" => true, "minLength" => 1, "pattern" => "^[a-zA-Z0-9 ]*$"},
                                   "elt_1" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
                                   "elt_2" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
                                   "elt_3" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
                                   "moos_if_missing" => {"type" => "string", "ifmissing" => "moo", "default" => ""},
                                   "no_shorty" => {"type" => "string", "required" => false, "default" => "", "minLength" => 6},
                                   "shorty" => {"type" => "string", "required" => false, "default" => "", "maxLength" => 2},
                                   "wants_integer" => {"type" => "integer", "required" => false},
                                 },

                                 "additionalProperties" => false
                               })

  end


  after(:all) do

    JSONModel.destroy_model(:testschema)
    JSONModel.destroy_model(:strictschema)

  end


  it "accepts a simple record" do

    JSONModel(:testschema).from_hash({
                                       "elt_0" => "helloworld",
                                       "elt_1" => "thisisatest"
                                     })

  end


  it "flags errors on invalid values" do

    lambda {
      JSONModel(:testschema).from_hash({"elt_0" => "/!$"})
    }.should raise_error(ValidationException)

  end


  it "provides accessors for non-schema properties but doesn't serialise them" do

    obj = JSONModel(:testschema).from_hash({
                                             "elt_0" => "helloworld",
                                             "special" => "some string"
                                           })

    obj.elt_0.should eq ("helloworld")
    obj.special.should eq ("some string")

    obj.to_hash.has_key?("special").should be_false
    JSON[obj.to_json].has_key?("special").should be_false

  end


  it "allows for updates" do

    obj = JSONModel(:testschema).from_hash({
                                             "elt_0" => "helloworld",
                                           })

    obj.elt_0 = "a new string"

    JSON[obj.to_json]["elt_0"].should eq("a new string")

  end


  it "throws an exception with some useful accessors" do

    exception = false
    begin
      JSONModel(:testschema).from_hash({"elt_0" => "/!$"})
    rescue ValidationException => e
      exception = e
    end

    exception.should_not be_false

    # You can still get at your invalid object if you really want.
    exception.invalid_object.elt_0.should eq("/!$")

    # And you can get a list of its problems too
    exception.errors["elt_0"][0].should eq "Did not match regular expression: ^[a-zA-Z0-9 ]*$"

  end


  it "warns on missing properties instead of erroring" do

    JSONModel::strict_mode(false)
    model = JSONModel(:testschema).from_hash({})

    model._warnings.keys.should eq(["elt_0"])
    JSONModel::strict_mode(true)

  end


  it "supports the 'ifmissing' definition" do

    JSONModel.create_model_for("strictschema",
                               {
                                 "type" => "object",
                                 "properties" => {
                                   "container" => {
                                     "type" => "object",
                                     "required" => true,
                                     "properties" => {
                                       "strict" => {"type" => "string", "ifmissing" => "error"},
                                     }
                                   }
                                 },
                               })

    JSONModel::strict_mode(false)

    model = JSONModel(:strictschema).from_hash({:container => {}}, false)

    model._exceptions[:errors].keys.should eq(["container/strict"])
    JSONModel::strict_mode(true)

  end


  it "can have its validation disabled" do

    ts = JSONModel(:testschema).new._always_valid!
    ts._exceptions.should eq({})

  end


  it "returns false if you ask for a model that doesn't exist" do

    JSONModel(:not_a_real_model).should eq false

  end


  it "can give a string representation of itself" do

    JSONModel(:testschema).to_s.should eq "JSONModel(:testschema)"

  end


  it "can give a string representation of an instance" do

    ts = JSONModel(:testschema).from_hash({
                                            "elt_0" => "helloworld",
                                            "elt_1" => "thisisatest"
                                          })
    ts.to_s.should match /\#<JSONModel\(:testschema\).*"elt_0"=>"helloworld".*>/

  end


  it "knows a bad uri when it sees one" do

    expect { JSONModel(:testschema).id_for("/moo/moo") }.to raise_error

  end


  it "supports setting values for properties" do

    ts = JSONModel(:testschema).from_hash({
                                            "elt_0" => "helloworld",
                                            "elt_1" => "thisisatest"
                                          })
    ts[:elt_2] = "a value has been set"
    ts[:elt_2].should eq "a value has been set"

  end


  it "returns nil if you try to look it up in a bad hash" do

    JSONModel(:testschema).lookup({}).should eq nil

  end


  it "enforces minimum length of property values" do

    ts = JSONModel(:testschema).from_hash({
                                            "elt_0" => "helloworld",
                                            "elt_1" => "thisisatest"
                                          })
    ts[:no_shorty] = "meep"
    ts._exceptions[:errors].keys.should eq (["no_shorty"])

  end


  it "enforces the type of property values" do

    ts = JSONModel(:testschema).from_hash({
                                            "elt_0" => "helloworld",
                                            "elt_1" => "thisisatest"
                                          })
    ts[:wants_integer] = "meep"
    ts._exceptions[:errors].keys.should eq (["wants_integer"])

  end


  it "copes with unexpected kinds of validation exception" do

    ts = JSONModel(:testschema).from_hash({
                                            "elt_0" => "helloworld",
                                            "elt_1" => "thisisatest"
                                          })
    ts[:shorty] = "meep"
    begin
      real_stdout = $stdout
      $stdout = StringIO.new
      ts._exceptions[:errors].keys.should eq ([:unknown])
    ensure
      $stdout = real_stdout
    end

  end

  it "can give a string representation of a validation exception" do

    begin
      JSONModel(:testschema).from_hash({"elt_0" => "/!$"})
    rescue ValidationException => ve
      ve.to_s.should match /^\#<:ValidationException: /
    end

  end

end
