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
                                   "wants_testschema_object" => {"type" => "JSONModel(:testschema) object"},
                                   "wants_this_or_that_schema" => {"type" => [{"type" => "JSONModel(:testschema) object"},
                                                                              {"type" => "JSONModel(:strictschema) object"},
                                                                              {"type" => "JSONModel(:treeschema) object"}]},
                                   "wants_red_green_or_blue" => {"type" => "string", "enum" => ["red", "green", "blue"]},
                                 },

                                 "additionalProperties" => false
                               })

  end


  after(:all) do

    JSONModel.destroy_model(:testschema)
    JSONModel.destroy_model(:strictschema)
    JSONModel.destroy_model(:treeschema)
    JSONModel.destroy_model(:urilessschema)
  end


  it "accepts a simple record" do
    JSONModel(:testschema).from_hash({
                                       "elt_0" => "helloworld",
                                       "elt_1" => "thisisatest"
                                     })
  end


  it "can give a list of models" do
    JSONModel.models.keys.should include("testschema")
  end


  it "rreturns nil  if you ask it for a schema source for a non-existent schema" do
    JSONModel.schema_src("somenonexistenttestschema").should be_nil
  end


  it "raises an error if you try to substitute a symbol into a uri" do
    expect { JSONModel(:testschema).substitute_parameters("/uri/number/:number", :number => :wtf) }.to raise_error(RuntimeError)
  end


  it "can recognize a valid url" do
    expect {
      JSONModel(:testschema).from_hash({"elt_0" => "001", "url" => "http://www.foo.bar"})
    }.not_to raise_error
  end


  it "flags errors on invalid values" do

    lambda {
      JSONModel(:testschema).from_hash({"elt_0" => "/!$"})
    }.should raise_error(JSONModel::ValidationException)

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
    rescue JSONModel::ValidationException => e
      exception = e
    end

    exception.should_not be_falsey

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


  it "raises an error if you ask for an id from a uri for a schema that doesn't have a uri property" do
    JSONModel.create_model_for("urilessschema",
                               {
                                 "type" => "object",
                                 "$schema" => "http://www.archivesspace.org/archivesspace.json",
                                 "properties" => {},
                               })

    expect { JSONModel(:urilessschema).id_for("/some/joke/of/a/uri") }.to raise_error(RuntimeError)
  end


  it "can have its validation disabled" do
    ts = JSONModel(:testschema).new._always_valid!
    ts._exceptions.should eq({})
  end


  it "returns false if you ask for a model that doesn't exist" do
    expect { JSONModel(:not_a_real_model) }.to raise_error(RuntimeError)
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

    expect { JSONModel(:testschema).id_for("/moo/moo") }.to raise_error(RuntimeError)

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
      .should be_truthy
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


  it "enforces maximum length of property values" do

    ts = JSONModel(:testschema).from_hash({
                                            "elt_0" => "helloworld",
                                            "elt_1" => "thisisatest"
                                          })
    ts[:shorty] = "waaaaaaaay too long dude"
    ts._exceptions[:errors].keys.should eq (["shorty"])

  end


  it "enforces the type of property values" do

    ts = JSONModel(:testschema).from_hash({
                                            "elt_0" => "helloworld",
                                            "elt_1" => "thisisatest"
                                          })
    ts[:wants_integer] = "meep"
    ts._exceptions[:errors].keys.should eq (["wants_integer"])

  end


  it "enforces ArchivesSpace type property values" do

    ts = JSONModel(:testschema).from_hash({
                                            "elt_0" => "helloworld",
                                            "elt_1" => "thisisatest"
                                          })
    ts[:wants_testschema_object] = "actually just a string"
    ts._exceptions[:errors].keys.should eq (["wants_testschema_object"])

  end


  it "enforces multiple ArchivesSpace type property values" do

    ts = JSONModel(:testschema).from_hash({
                                            "elt_0" => "helloworld",
                                            "elt_1" => "thisisatest"
                                          })
    ts[:wants_this_or_that_schema] = "actually just a string"
    ts._exceptions[:errors].keys.should eq (["wants_this_or_that_schema"])
  end


  it "enforces old fashioned enums" do

    ts = JSONModel(:testschema).from_hash({
                                            "elt_0" => "helloworld",
                                            "elt_1" => "thisisatest"
                                          })
    ts[:wants_red_green_or_blue] = "yellow"
    ts._exceptions[:errors].keys.should eq (["wants_red_green_or_blue"])
  end


  it "can give a string representation of a validation exception" do

    begin
      JSONModel(:testschema).from_hash({"elt_0" => "/!$"})
    rescue JSONModel::ValidationException => ve
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
                                       "dates" => [{"jsonmodel_type" => "date",
                                                      "expression" => "1666",
                                                     "date_type" => "single",
                                                     "label" => "creation"}],
                                       "level" => "collection",
                                       "notes" => [{"jsonmodel_type" => "note_singlepart",
                                                     "type" => "abstract",
                                                     "label" => "moo"},
                                                   {"jsonmodel_type" => "note_multipart",
                                                     "type" => "accruals",
                                                     "content" => ["moo"],
                                                     "label" => "moo",
                                                     "subnotes" => [{"jsonmodel_type" => "note_definedlist",
                                                      "items" => [["label" => "should_have_been_an_object"]]
                                                      }]}],
                                       "extents" => [{"portion" => "whole",
                                                       "number" => "5",
                                                       "extent_type" => "cassettes",
                                                       "container_summary" => "",
                                                       "physical_details" => "",
                                                       "dimensions" => ""}]})

    rescue JSONModel::ValidationException => e
      e.errors.keys.sort.should eq(["notes/0/content",
                                    "notes/1/subnotes/0/items/0" # wrong type
                                   ])
    end
  end


  it "reports errors correctly for simple errors too" do
    begin
      JSONModel(:subject).from_hash({
                                      "source" => "local",
                                      "vocabulary" => "/vocabularies/1",
                                      "terms" => [{
                                                    "term" => "",
                                                    "term_type" => "cultural_context",
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
    rescue JSONModel::ValidationException => ve
      ve.to_s.should match /^\#<:ValidationException: /
    end

    # Abstract archival object don't allow language to be klingon
    expect {
      create(:json_resource, {:language => "klingon"})
    }.to raise_error(JSONModel::ValidationException)

    # Abstract archival objects do allow language to be nil
    expect {
      create(:json_archival_object, {:language => nil})
    }.to_not raise_error
  end


  it "supports a magic 'other_unmapped' enum value which is always acceptable" do
    term = build(:json_term)

    term.term_type = 'garbage'
    expect {
      term.to_hash
    }.to raise_error(JSONModel::ValidationException)

    term.term_type = 'other_unmapped'
    expect {
      term.to_hash
    }.to_not raise_error
  end


  it "supports validations across multiple threads" do
    threads = []

    threads << Thread.new do
      1000.times do
        build(:json_agent_person)
      end

      :ok
    end

    threads << Thread.new do
      1000.times do
        build(:json_resource, :instances => [])
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


  it "supports optional translatable enum to_hash method" do

    JSONModel.create_model_for("coolschema",
                               {
                                 "type" => "object",
                                 "$schema" => "http://www.archivesspace.org/archivesspace.json",
                                 "properties" => {
                                   "language" => {"type" => "string", "dynamic_enum" => "language_iso639_2"},
                                   "linked_agents" => {
                                     "type" => "array",
                                     "items" => {
                                       "type" => "object",
                                       "properties" => {
                                         "role" => {
                                           "type" => "string",
                                           "dynamic_enum" => "linked_agent_role",
                                           "ifmissing" => "error",
                                         }
                                       }
                                     }
                                   }
                                 }
                               })

    hash = {
      "language" => "eng",
      "linked_agents" => [{
                            'role' => 'creator'
                         }]
    }


    obj = JSONModel(:coolschema).from_hash(hash)

    hash = obj.to_hash_with_translated_enums(['language_iso639_2', 'linked_agent_role'])

    hash['language'].should eq("English")
    hash['linked_agents'].first['role'].should eq("Creator");
  end

end
