require 'spec_helper'

describe 'JSON model' do

  before(:all) do

    JSONModel.create_model_for("testschema",
                               {
                                 "$schema" => "http://www.archivesspace.org/archivesspace.json",
                                 "type" => "object",
                                 "uri" => "/testthings",
                                 "properties" => {
                                   "elt_0" => {"type" => "string", "required" => true, "minLength" => 1, "pattern" => "^[a-zA-Z0-9 ]*$"},
                                   "elt_1" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
                                   "elt_2" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
                                   "elt_3" => {"type" => "string", "required" => false, "default" => "", "pattern" => "^[a-zA-Z0-9]*$"},
                                   "url" => {"type" => "string", "pattern" => "^https?:\\/\\/[\\\S]+$"},
                                   "moos_if_missing" => {"type" => "string", "ifmissing" => "moo", "default" => ""},
                                   "no_shorty" => {"type" => "string", "required" => false, "default" => "", "minLength" => 6},
                                   "shorty" => {"type" => "string", "required" => false, "default" => "", "maxLength" => 2},
                                   "wants_integer" => {"type" => "integer", "required" => false},
                                   "wants_uri_or_object" => {"type" => "JSONModel(:testschema) uri_or_object"},
                                 },

                                 "additionalProperties" => false
                               })

  end


  after(:all) do

    JSONModel.destroy_model(:testschema)
    JSONModel.destroy_model(:strictschema)
    JSONModel.destroy_model(:treeschema)

  end


  it "accepts a simple record" do

    JSONModel(:testschema).from_hash({
                                       "elt_0" => "helloworld",
                                       "elt_1" => "thisisatest"
                                     })

  end
  
  it "can recognize a valid url" do
    lambda {
      JSONModel(:testschema).from_hash({"elt_0" => "001", "url" => "http://www.foo.bar"})
    }.should_not raise_error(ValidationException)
  end


  it "flags errors on invalid values" do

    lambda {
      JSONModel(:testschema).from_hash({"elt_0" => "/!$"})
    }.should raise_error(ValidationException)

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
                                 "$schema" => "http://www.archivesspace.org/archivesspace.json",
                                 "properties" => {
                                   "container" => {
                                     "type" => "object",
                                     "required" => true,
                                     "properties" => {
                                       "strict" => {"type" => "string", "ifmissing" => "error"},
                                       "lenient" => {"type" => "string"},
                                     }
                                   }
                                 },
                               })

    JSONModel::strict_mode(false)

    model = JSONModel(:strictschema).from_hash({:container => {'lenient' => 'ok'}}, false)
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


  it "supports adding errors to objects" do
    ts = JSONModel(:testschema).from_hash({
                                            "elt_0" => "helloworld",
                                            "elt_1" => "thisisatest"
                                          })
    ts.add_error("elt_0", "'hello world' is two words, you squashed them together")
    ts._exceptions[:errors]["elt_0"].include?("'hello world' is two words, you squashed them together")
      .should be_true
  end


  it "supports adding custom error handlers" do
    JSONModel::add_error_handler do |error|
      if error["code"] == "OUTTOLUNCH"
        raise NotFoundException.new("Seriously not good enough")
      end
    end
    expect {
      JSONModel::handle_error({"code" => "OUTTOLUNCH"})
    }.to raise_error(NotFoundException)
  end


  it "can set the current backend session token and get it back" do
    JSONModel::HTTP.current_backend_session = 'moo'
    JSONModel::HTTP.current_backend_session.should eq('moo')
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


  it "can give a string representation of a validation exception" do

    begin
      JSONModel(:testschema).from_hash({"elt_0" => "/!$"})
    rescue ValidationException => ve
      ve.to_s.should match /^\#<:ValidationException: /
    end

  end


  it "fails validation on a uri_or_object property whose value is neither a string nor a hash" do

    ts = JSONModel(:testschema).from_hash({
                                            "elt_0" => "helloworld",
                                            "elt_1" => "thisisatest"
                                          })
    ts[:wants_uri_or_object] = ["not", "a", "string", "or", "a", "hash"]
    ts._exceptions[:errors].keys.should eq(["wants_uri_or_object"])

  end


  it "doesn't lose existing errors when validating" do

    ts = JSONModel(:testschema).from_hash({
                                            "elt_0" => "helloworld",
                                            "elt_1" => "thisisatest"
                                          })

    # it's not clear to me how @errors would legitimately be set
    ts.instance_variable_set(:@errors, {"a_terrible_thing" => "happened earlier"})
    ts._exceptions[:errors].keys.should eq(["a_terrible_thing"])

  end


  it "reports errors correctly for complicated resources with notes" do
    begin
      JSONModel(:resource).from_hash({"title" => "New Resource",
                                       "id_0" => "ABCD",
                                       "language" => "eng",
                                       "level" => "collection",
                                       "notes" => [{"jsonmodel_type" => "note_singlepart",
                                                     "type" => "abstract",
                                                     "label" => "moo"},
                                                   {"jsonmodel_type" => "note_multipart",
                                                     "type" => "accruals",
                                                     "content" => ["moo"],
                                                     "label" => "moo",
                                                     "subnotes" => [{"jsonmodel_type" => "note_definedlist"}]}],
                                       "extents" => [{"portion" => "whole",
                                                       "number" => "5",
                                                       "extent_type" => "cassettes",
                                                       "container_summary" => "",
                                                       "physical_details" => "",
                                                       "dimensions" => ""}]})

    rescue JSONModel::ValidationException => e
      e.errors.keys.sort.should eq(["notes/0/content",
                                    "notes/1/subnotes/0/title"])
    end
  end


  it "reports errors correctly for simple errors too" do
    begin
      JSONModel(:subject).from_hash({"vocabulary" => "/vocabularies/1",
                                      "terms" => [{
                                                    "term" => "",
                                                    "term_type" => "Cultural context",
                                                    "vocabulary" => "/vocabularies/1"
                                                  }]})
    rescue JSONModel::ValidationException => e
      e.errors.keys.sort.should eq(["terms/0/term"])
    end

  end
  
  it "allows a schema to override the ifmissing key of its abstract parent" do
    
    # Resources don't allow language to be nil
    begin
      create(:json_resource, {:language => nil})      
    rescue ValidationException => ve
      ve.to_s.should match /^\#<:ValidationException: /
    end
    
    # Abstract archival object don't allow language to be klingon
    expect {
      create(:json_resource, {:language => "klingon"}) 
    }.to raise_error
    
    # Abstract archival objects do allow language to be nil
    expect {
      create(:json_archival_object, {:language => nil})
    }.to_not raise_error
  end


  it "supports a magic 'other_unmapped' enum value which is always acceptable" do
    term = build(:json_term)

    term.term_type = 'garbage'
    expect {
      term.save
    }.to raise_error(ValidationException)

    term.term_type = 'other_unmapped'
    expect {
      term.save
    }.to_not raise_error(ValidationException)
  end


  it "supports validations across multiple threads" do
    threads = []

    threads << Thread.new do
      1000.times do
        build(:json_archival_object)
      end

      :ok
    end

    threads << Thread.new do
      1000.times do
        build(:json_resource)
      end

      :ok
    end

    threads << Thread.new do
      1000.times do
        build(:json_accession)
      end

      :ok
    end

    threads << Thread.new do
      1000.times do
        begin
          build(:json_accession, :title => nil)
        rescue JSONModel::ValidationException => e
          e.errors.keys == ["title"] or raise "Oops: #{e.inspect}"
        end
      end

      :ok
    end


    threads.each do |t|
      t.join
      t.value.should eq(:ok)
    end
  end

end
