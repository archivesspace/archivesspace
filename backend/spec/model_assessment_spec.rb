require 'spec_helper'
require 'assessment_spec_helper'

describe 'Assessment model' do

  before(:all) do
    AssessmentSpecHelper.setup_global_attributes
  end

  let(:resource) { create_resource }
  let(:surveyor) { create(:json_agent_person) }
  let(:reviewer) { create(:json_agent_person) }

  it "can create an assessment" do
    assessment = Assessment.create_from_json(build(:json_assessment, {
                                                     'records' => [{'ref' => resource.uri}],
                                                     'surveyed_by' => [{'ref' => surveyor.uri}],
                                                   }))

    json = Assessment.to_jsonmodel(assessment.id)
    json.should_not be_nil
    json.records.should_not be_empty
    json.records.first['ref'].should eq(resource.uri)

    json.surveyed_by.should_not be_empty
    json.surveyed_by.first['ref'].should eq(surveyor.uri)
  end


  it "can create assign a reviewer" do
    assessment = Assessment.create_from_json(build(:json_assessment, {
      'records' => [{'ref' => resource.uri}],
      'surveyed_by' => [{'ref' => surveyor.uri}],
      'reviewer' => [{'ref' => reviewer.uri}],
    }))

    json = Assessment.to_jsonmodel(assessment.id)
    json.should_not be_nil
    json.reviewer.should_not be_empty
    json.reviewer.first['ref'].should eq(reviewer.uri)
  end


  it "gets back the global rating" do
    assessment = Assessment.create_from_json(build(:json_assessment, {
                                                     'records' => [{'ref' => resource.uri}],
                                                     'surveyed_by' => [{'ref' => surveyor.uri}],
                                                   }))

    json = Assessment.to_jsonmodel(assessment.id)

    json.ratings.length.should eq(1)
    json.ratings[0]['value'].should be(nil)
  end


  it "sets a value for a rating and gets it back" do
    definitions = AssessmentAttributeDefinitions.get($repo_id)

    assessment = Assessment.create_from_json(
      build(:json_assessment, {
              'records' => [{'ref' => resource.uri}],
              'surveyed_by' => [{'ref' => surveyor.uri}],
              'ratings' => [
                {
                  "definition_id" => definitions.definitions[0].fetch(:id),
                  "value" => "5",
                }
              ],
            })
    )

    json = Assessment.to_jsonmodel(assessment.id)

    json.ratings.length.should eq(1)
    json.conservation_issues.length.should eq(1)
    json.formats.length.should eq(1)

    json.ratings[0]['value'].should eq('5')
  end


  it "complains if survey dates are badly formed" do
    expect {
      Assessment.create_from_json(build(:json_assessment, {
        'records' => [{'ref' => resource.uri}],
        'surveyed_by' => [{'ref' => surveyor.uri}],
        'survey_begin' => '26 May 1967',
      }))
    }.to raise_error(JSONModel::ValidationException)

    expect {
      Assessment.create_from_json(build(:json_assessment, {
        'records' => [{'ref' => resource.uri}],
        'surveyed_by' => [{'ref' => surveyor.uri}],
        'survey_end' => '1977/10/28',
      }))
    }.to raise_error(JSONModel::ValidationException)
  end


  it "complains if survey end is before survey begin" do
    expect {
      Assessment.create_from_json(build(:json_assessment, {
        'records' => [{'ref' => resource.uri}],
        'surveyed_by' => [{'ref' => surveyor.uri}],
        'survey_begin' => '1970-01-01',
        'survey_end' => '1969-08-15',
      }))
    }.to raise_error(JSONModel::ValidationException)

    # no end date is fine
    expect {
      Assessment.create_from_json(build(:json_assessment, {
        'records' => [{'ref' => resource.uri}],
        'surveyed_by' => [{'ref' => surveyor.uri}],
        'survey_begin' => '1969-07-20',
        'survey_end' => '',
      }))
    }.to_not raise_error

    # begin and end the saem is also fine
    expect {
      Assessment.create_from_json(build(:json_assessment, {
        'records' => [{'ref' => resource.uri}],
        'surveyed_by' => [{'ref' => surveyor.uri}],
        'survey_begin' => '1963-11-22',
        'survey_end' => '1963-11-22',
      }))
    }.to_not raise_error
  end


  it "validates monetary value as a two position decimal" do
    # random string
    expect {
      Assessment.create_from_json(build(:json_assessment, {
        'records' => [{'ref' => resource.uri}],
        'surveyed_by' => [{'ref' => surveyor.uri}],
        'monetary_value' => 'not a decimal',
      }))
    }.to raise_error(JSONModel::ValidationException)

    # too many decimal places
    expect {
      Assessment.create_from_json(build(:json_assessment, {
        'records' => [{'ref' => resource.uri}],
        'surveyed_by' => [{'ref' => surveyor.uri}],
        'monetary_value' => '10.123',
      }))
    }.to raise_error(JSONModel::ValidationException)

    # the second decimal place is free!
    expect {
      assessment = Assessment.create_from_json(build(:json_assessment, {
        'records' => [{'ref' => resource.uri}],
        'surveyed_by' => [{'ref' => surveyor.uri}],
        'monetary_value' => '10.1',
      }))

      Assessment.to_jsonmodel(assessment.id).monetary_value.should eq('10.10')

    }.to_not raise_error

    # perfect!
    expect {
      Assessment.create_from_json(build(:json_assessment, {
        'records' => [{'ref' => resource.uri}],
        'surveyed_by' => [{'ref' => surveyor.uri}],
        'monetary_value' => '10.12',
      }))
    }.to_not raise_error
  end


  it "saves monetary value as decimal and formats as string" do
    assessment = Assessment.create_from_json(build(:json_assessment, {
      'records' => [{'ref' => resource.uri}],
      'surveyed_by' => [{'ref' => surveyor.uri}],
      'monetary_value' => '10.12',
    }))

    Assessment[assessment.id].monetary_value.should eq(10.12)
    Assessment.to_jsonmodel(assessment.id).monetary_value.should eq('10.12')
  end


  it "can delete an assessment" do
    assessment = Assessment.create_from_json(build(:json_assessment, {
      'records' => [{'ref' => resource.uri}],
      'surveyed_by' => [{'ref' => surveyor.uri}],
    }))

    assessment.delete

    Assessment[assessment.id].should be(nil)
  end


  it "doesn't allow delete of a record when linked to an assessment" do
    assessment = Assessment.create_from_json(build(:json_assessment, {
      'records' => [{'ref' => resource.uri}],
      'surveyed_by' => [{'ref' => surveyor.uri}],
    }))

    expect {
      resource.delete
    }.to raise_error(ConflictException)

    assessment.delete

    expect {
      resource.delete
    }.to_not raise_error
  end


  it "doesn't allow delete of a surveyor agent when linked to an assessment" do
    assessment = Assessment.create_from_json(build(:json_assessment, {
      'records' => [{'ref' => resource.uri}],
      'surveyed_by' => [{'ref' => surveyor.uri}],
    }))

    expect {
      surveyor.delete
    }.to raise_error(ConflictException)

    assessment.delete

    expect {
      surveyor.delete
    }.to_not raise_error
  end


  it "doesn't allow delete of a reviewer agent when linked to an assessment" do
    assessment = Assessment.create_from_json(build(:json_assessment, {
      'records' => [{'ref' => resource.uri}],
      'surveyed_by' => [{'ref' => surveyor.uri}],
      'reviewer' => [{'ref' => reviewer.uri}],
    }))

    expect {
      reviewer.delete
    }.to raise_error(ConflictException)

    assessment.delete

    expect {
      reviewer.delete
    }.to_not raise_error
  end


  it "returns the collections of the records linked" do
    assessment = Assessment.create_from_json(build(:json_assessment, {
      'records' => [{'ref' => resource.uri}],
      'surveyed_by' => [{'ref' => surveyor.uri}],
    }))

    json = Assessment.to_jsonmodel(assessment.id)
    json.collections.length.should eq(1)
    json.collections.first['ref'].should eq(resource.uri)
  end


  it "returns the collections of the archival object linked" do
    archival_object = create(:json_archival_object, 'resource' => {
      'ref'=> resource.uri
    })

    assessment = Assessment.create_from_json(build(:json_assessment, {
      'records' => [{'ref' => archival_object.uri}],
      'surveyed_by' => [{'ref' => surveyor.uri}],
    }))

    json = Assessment.to_jsonmodel(assessment.id)
    json.collections.length.should eq(1)
    json.collections.first['ref'].should eq(resource.uri)
  end


  describe "repository attributes" do

    before(:all) do
      AssessmentSpecHelper.setup_global_attributes
    end

    before(:each) do
      JSONModel(:assessment_attribute_definitions)
        .from_hash('definitions' => [
                     {
                       'label' => 'Rating',
                       'type' => 'rating',
                     },
                     {
                       'label' => 'Format',
                       'type' => 'format',
                     },
                     {
                       'label' => 'Conservation Issue',
                       'type' => 'conservation_issue',
                     }
                   ])
        .save
    end


    it "complains if you give a definition a bad type" do
      expect {
        JSONModel(:assessment_attribute_definitions)
          .from_hash('definitions' => [
                                       {
                                         'label' => 'Rating',
                                         'type' => 'bad non rating type',
                                       }
                                      ])
          .save
      }.to raise_error(JSONModel::ValidationException)
    end


    it "complains if there is a bad definition type in the database" do
      AssessmentSpecHelper.setup_bad_definition

      assessment = Assessment.create_from_json(build(:json_assessment, {
                                                       'records' => [{'ref' => resource.uri}],
                                                       'surveyed_by' => [{'ref' => surveyor.uri}],
                                                     }))

      expect {
        Assessment.to_jsonmodel(assessment.id)
      }.to raise_error(RuntimeError)
    end


    it "complains if you give a duplicate global definition label" do
      expect {
        JSONModel(:assessment_attribute_definitions)
          .from_hash('definitions' => [
                                       {
                                         'label' => 'Global Rating',
                                         'type' => 'rating',
                                       }
                                      ])
          .save
      }.to raise_error(ConflictException)
    end


    it "complains if you give a duplicate repository definition label" do
      expect {
        JSONModel(:assessment_attribute_definitions)
          .from_hash('definitions' => [
                                       {
                                         'label' => 'Rating',
                                         'type' => 'rating',
                                       },
                                       {
                                         'label' => 'Other Rating',
                                         'type' => 'rating',
                                       }
                                      ])
          .save

        defns = JSONModel::HTTP.get_json("/repositories/#{$repo_id}/assessment_attribute_definitions")

        defns['definitions'].each do |defn|
          # Force a conflict
          if defn['label'] == 'Other Rating'
            defn['label'] = 'Rating'
          end
        end

        JSONModel(:assessment_attribute_definitions).from_hash(defns).save
      }.to raise_error(ConflictException)
    end


    it "successfully sets a value for a repository attribute" do
      assessment = Assessment.create_from_json(build(:json_assessment, {
                                                       'records' => [{'ref' => resource.uri}],
                                                       'surveyed_by' => [{'ref' => surveyor.uri}],
                                                     }))

      json = Assessment.to_jsonmodel(assessment.id)

      json.ratings.length.should eq(2) # one global, one repo
      json.formats.length.should eq(2)
      json.conservation_issues.length.should eq(2)

      # Set a value
      json.formats[0]['value'] = 'true'

      Assessment[assessment.id].update_from_json(json)

      json = Assessment.to_jsonmodel(assessment.id)
      json.formats[0]['value'].should eq('true')
    end


    it "can delete an assessment with repo attributes" do
      assessment = Assessment.create_from_json(build(:json_assessment, {
        'records' => [{'ref' => resource.uri}],
        'surveyed_by' => [{'ref' => surveyor.uri}],
      }))

      json = Assessment.to_jsonmodel(assessment.id)
      json.formats[0]['value'] = 'true'
      json.ratings[0]['value'] = '5'
      json.ratings[1]['value'] = '4'
      json.conservation_issues[0]['value'] = 'true'
      Assessment[assessment.id].update_from_json(json)

      Assessment[assessment.id].delete

      Assessment[assessment.id].should be(nil)
    end
  end

  describe "research value" do
    before(:all) do
      AssessmentSpecHelper.setup_research_value_ratings
    end

    let(:interest_definition) {
      AssessmentAttributeDefinitions.get($repo_id).definitions.detect{|d| d[:type] == 'rating' && d[:label] == 'Interest'}
    }

    let(:documentation_quality_definition) {
      AssessmentAttributeDefinitions.get($repo_id).definitions.detect{|d| d[:type] == 'rating' && d[:label] == 'Documentation Quality'}
    }

    def get_research_value(assessment)
      Assessment.to_jsonmodel(assessment.id).ratings.find {|r| r['label'] == 'Research Value'}.fetch('value')
    end

    it "calculated correctly when there are no ratings" do
      assessment = Assessment.create_from_json(build(:json_assessment, {
                                                       'records' => [{'ref' => resource.uri}],
                                                       'surveyed_by' => [{'ref' => surveyor.uri}]
                                                     }))

      get_research_value(assessment).should be_nil
    end

    it "calculated correctly when there is only Interest rating" do
      assessment = Assessment.create_from_json(build(:json_assessment, {
                                                       'records' => [{'ref' => resource.uri}],
                                                       'surveyed_by' => [{'ref' => surveyor.uri}],
                                                       'ratings' => [
                                                         {
                                                           "definition_id" => interest_definition.fetch(:id),
                                                           "value" => "5",
                                                         }
                                                       ],
                                                     }))

      get_research_value(assessment).should eq('5')
    end

    it "calculated correctly when there is only Documentation Quality rating" do
      assessment = Assessment.create_from_json(build(:json_assessment, {
                                                       'records' => [{'ref' => resource.uri}],
                                                       'surveyed_by' => [{'ref' => surveyor.uri}],
                                                       'ratings' => [
                                                         {
                                                           "definition_id" => documentation_quality_definition.fetch(:id),
                                                           "value" => "4",
                                                         }
                                                       ],
                                                     }))

      get_research_value(assessment).should eq('4')
    end

    it "calculated correctly when both ratings provided" do
      assessment = Assessment.create_from_json(build(:json_assessment, {
                                                       'records' => [{'ref' => resource.uri}],
                                                       'surveyed_by' => [{'ref' => surveyor.uri}],
                                                       'ratings' => [
                                                         {
                                                           "definition_id" => interest_definition.fetch(:id),
                                                           "value" => "5",
                                                         },
                                                         {
                                                           "definition_id" => documentation_quality_definition.fetch(:id),
                                                           "value" => "4",
                                                         }
                                                       ],
                                                     }))

      get_research_value(assessment).should eq('9')
    end
  end



end
