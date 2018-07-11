require 'spec_helper'
require 'assessment_spec_helper'

describe 'Assessment attribute definitions controller' do

  before(:all) do
    AssessmentSpecHelper.setup_global_attributes
  end

  let (:sample_definitions) {
    AssessmentSpecHelper.sample_definitions
  }

  it "creates some definitions and lets you get them back" do
    JSONModel(:assessment_attribute_definitions)
      .from_hash('definitions' => sample_definitions)
      .save

    aad = JSONModel(:assessment_attribute_definitions).find(nil)

    aad.definitions.map {|d| d['label']}.should eq(sample_definitions.map {|d| d['label']})
  end

  it "updates definitions and gets the order right" do
    # create them
    JSONModel(:assessment_attribute_definitions)
      .from_hash('definitions' => sample_definitions)
      .save

    aad = JSONModel(:assessment_attribute_definitions).find(nil)

    aad.definitions = aad.definitions.shuffle

    aad.save

    JSONModel(:assessment_attribute_definitions).find(nil)
      .definitions.reject {|d| d['global']}.map {|d| d['label']}
      .should eq(aad.definitions.reject {|d| d['global']}.map {|d| d['label']})
  end

  it "implicitly removes (unused) definitions if you omit them from an update" do
    # create them
    JSONModel(:assessment_attribute_definitions)
      .from_hash('definitions' => sample_definitions)
      .save

    aad = JSONModel(:assessment_attribute_definitions).find(nil)
    aad.definitions = [{
        'label' => 'New Definition',
        'type' => 'rating',
      }]
    aad.save

    global_labels = sample_definitions.map {|d|
      if d['global']
        d['label']
      end
    }.compact

    # The new definition shares a position with the original entry, but that's
    # OK.  As long as they're both kept.
    JSONModel(:assessment_attribute_definitions).find(nil).definitions.map {|d| d['label']}
      .should eq(global_labels + ['New Definition'])
  end

  it "returns the global definitions too" do
    aad = JSONModel(:assessment_attribute_definitions).find(nil)

    aad.definitions.length.should be > 0

    aad.definitions.all? {|d| d['repo_id'] == 1}
  end

  it "reports a conflict if you attempt to delete attributes that are linked to an assessment" do
    JSONModel(:assessment_attribute_definitions)
      .from_hash('definitions' => sample_definitions)
      .save

    aad = JSONModel(:assessment_attribute_definitions).find(nil)

    repo_rating = aad.definitions.find {|d| d['type'] == 'rating' && !d['global']}

    resource = create_resource
    surveyor = create(:json_agent_person)

    assessment = Assessment.create_from_json(build(:json_assessment, {
                                                     'records' => [{'ref' => resource.uri}],
                                                     'surveyed_by' => [{'ref' => surveyor.uri}],
                                                     'ratings' => [{
                                                                     'definition_id' => repo_rating['id'],
                                                                     'value' => '3'
                                                                   }]
                                                   }))

    # Blank the definitions to remove all repository-scoped attributes
    # (including the one we just used).
    aad.definitions = []

    expect { aad.save }.to raise_error(ConflictException)
  end

end
