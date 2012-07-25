require 'spec_helper'

describe 'JSON model' do

  before(:all) do

    JSONModel.instance_eval do
      $schema[:testschema] = {
        "type" => "object",
        "properties" => {
          "elt_0" => {"type" => "string", "required" => true, "minLength" => 1, "pattern" => "^[a-zA-Z0-9 ]*$"},
          "elt_1" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
          "elt_2" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
          "elt_3" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
        },

        "additionalProperties" => false
      }
    end

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
    }.should raise_error(JSONValidationException)
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
    rescue JSONValidationException => e
      exception = e
    end

    exception.should_not be_false

    # You can still get at your invalid object if you really want.
    exception.invalid_object.elt_0.should eq("/!$")

    # And you can get a list of its problems too
    exception.errors[0][:failed_attribute].should eq("Pattern")
  end


end
