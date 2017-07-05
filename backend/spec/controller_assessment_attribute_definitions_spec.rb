require 'spec_helper'

describe 'Assessment attribute definitions controller' do

  let (:sample_definitions) {
    [
      {
        'label' => 'Reformatting Readiness',
        'type' => 'rating',
      },
      {
        'label' => 'Interest',
        'type' => 'rating',
      },
      {
        'label' => 'Architectural Materials?',
        'type' => 'format',
      },
      {
        'label' => 'Artifacts?',
        'type' => 'format',
      },
      {
        'label' => 'Newspaper?',
        'type' => 'conservation_issue',
      },
      {
        'label' => 'Metal Fasteners?',
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

    JSONModel(:assessment_attribute_definitions).find(nil).definitions.map {|d| d['label']}
      .should eq(aad.definitions.map {|d| d['label']})
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
      .should eq(labels.take(1) + ['New Definition'] + labels.drop(1))
  end

end
