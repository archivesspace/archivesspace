require 'spec_helper'
require 'assessment_spec_helper'

describe 'Assessment controller' do

  before(:all) do
    AssessmentSpecHelper.setup_global_attributes
  end

  let(:resource) { create_resource }
  let(:surveyor) { create(:json_agent_person) }

  def create_assessment(additional_properties = {})
    create(:json_assessment,
           {
             'records' => [{'ref' => resource.uri}],
             'surveyed_by' => [{'ref' => surveyor.uri}]
           }.merge(additional_properties))
  end

  it 'creates an assessment and gets it back' do
    created = create_assessment
    fetched = JSONModel(:assessment).find(created.id)

    fetched.records[0]['ref'].should eq(resource.uri)
    fetched.surveyed_by[0]['ref'].should eq(surveyor.uri)
  end

  it 'updates an assessment record' do
    created = create_assessment('survey_begin' => '1970-01-01', 'survey_end' => '2000-01-01')

    fetched = JSONModel(:assessment).find(created.id)
    fetched['survey_end'].should eq('2000-01-01')

    fetched['survey_end'] = '2017-01-01'
    fetched.save

    fetched.refetch
    fetched['survey_end'].should eq('2017-01-01')
  end

  it 'lists assessment records' do
    5.times do
      create_assessment
    end

    JSONModel(:assessment).all(:page => 1, :page_size => 10)['results'].count.should eq(5)
  end

  it 'deletes an assessment record' do
    created = create_assessment
    fetched = JSONModel(:assessment).find(created.id)

    fetched.delete

    expect { fetched.refetch }.to raise_error(RecordNotFound)
  end
end
