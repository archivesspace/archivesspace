require 'spec_helper'

def resource_duplicate_job(resource_uri)
  build( :json_job,
         :job => build(:json_resource_duplicate_job,
                       source: resource_uri)
       )
end

describe 'Resource Duplicate job' do
  let(:user) { create_nobody_user }
  let(:resource) { Resource.create_from_json(build(:json_resource)) }

  before(:each) do
    allow(::Lib::Resource::Duplicate).to receive(:new).and_call_original
  end

  it 'calls duplicate wih the resource id' do
    json = resource_duplicate_job(resource.uri)
    job = Job.create_from_json(json, :user => user )
    jr = JobRunner.for(job)
    jr.run

    expect(::Lib::Resource::Duplicate).to have_received(:new).with(resource.id, [])
  end

  context 'when AppConfig[:resource_fields_not_to_duplicate] has content' do
    before(:each) do
      allow(AppConfig).to receive(:[]).and_call_original
      allow(AppConfig).to receive(:[]).with(:resource_fields_not_to_duplicate) { ['finding_aid_status'] }
    end

    it 'calls duplicate wih the resource id and array from AppConfig' do
      json = resource_duplicate_job(resource.uri)
      job = Job.create_from_json(json, :user => user )
      jr = JobRunner.for(job)
      jr.run

      expect(::Lib::Resource::Duplicate).to have_received(:new).with(resource.id, ['finding_aid_status'])
    end
  end
end
