require 'spec_helper'

describe 'Assessment attribute definitions controller' do

  before(:all) do
    DB.open do |db|
      db[:assessment_attribute_definition].filter(:repo_id => 1).delete
      db[:assessment_attribute_definition].insert(:repo_id => 1, :label => "Global Rating", :type => "rating", :position => 0)
    end
  end

  let (:sample_definitions) {
    [
      {
        'label' => 'Global Rating',
        'type' => 'rating',
        'global' => true,
      },
      {
        'label' => 'Rating 1',
        'type' => 'rating',
      },
      {
        'label' => 'Rating 2',
        'type' => 'rating',
      },
      {
        'label' => 'Format 1',
        'type' => 'format',
      },
      {
        'label' => 'Format 2',
        'type' => 'format',
      },
      {
        'label' => 'Conservation Issue 1',
        'type' => 'conservation_issue',
      },
      {
        'label' => 'Conservation Issue 2',
        'type' => 'conservation_issue',
      }
    ]
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

  it "doesn't lose anything if you try a partial update" do
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

    labels = sample_definitions.map {|d| d['label']}

    # The new definition shares a position with the original entry, but that's
    # OK.  As long as they're both kept.
    JSONModel(:assessment_attribute_definitions).find(nil).definitions.map {|d| d['label']}
      .should eq(labels.take(2) + ['New Definition'] + labels.drop(2))
  end

  it "returns the global definitions too" do
    aad = JSONModel(:assessment_attribute_definitions).find(nil)

    aad.definitions.length.should be > 0

    aad.definitions.all? {|d| d['repo_id'] == 1}
  end


end
