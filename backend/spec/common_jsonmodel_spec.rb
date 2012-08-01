require 'spec_helper'

describe 'JSON model' do

  before(:all) do

    JSONModel.create_model_for("testschema",
                               {
                                 "type" => "object",
                                 "properties" => {
                                   "elt_0" => {"type" => "string", "required" => true, "minLength" => 1, "pattern" => "^[a-zA-Z0-9 ]*$"},
                                   "elt_1" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
                                   "elt_2" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
                                   "elt_3" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
                                 },

                                 "additionalProperties" => false
                               })
  end

  it "Accepts a simple record" do
    JSONModel(:testschema).from_hash({
      "elt_0" => "helloworld",
      "elt_1" => "thisisatest"
    })
  end


  it "Flags errors on invalid values" do
    lambda {
      JSONModel(:testschema).from_hash({"elt_0" => "/!$"})
    }.should raise_error(ValidationException)
  end


  it "Provides accessors for non-schema properties but doesn't serialise them" do
    obj = JSONModel(:testschema).from_hash({
                                             "elt_0" => "helloworld",
                                             "special" => "some string"
                                           })

    obj.elt_0.should eq ("helloworld")
    obj.special.should eq ("some string")

    obj.to_hash.has_key?("special").should be_false
    JSON[obj.to_json].has_key?("special").should be_false
  end


  it "Allows for updates" do
    obj = JSONModel(:testschema).from_hash({
                                             "elt_0" => "helloworld",
                                           })

    obj.elt_0 = "a new string"

    JSON[obj.to_json]["elt_0"].should eq("a new string")
  end


  it "Throws an exception with some useful accessors" do
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


  it "Warns on missing properties instead of erroring" do
    JSONModel::strict_mode(false)
    model = JSONModel(:testschema).from_hash({})

    model._warnings.keys.should eq(["elt_0"])
    JSONModel::strict_mode(true)
  end


end
