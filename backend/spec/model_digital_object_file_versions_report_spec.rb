require 'spec_helper'

describe DigitalObjectFileVersionsReport do
  let(:repo)  { Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                      :name => "My new test repository")) }
  let(:datab) { Sequel.connect(AppConfig[:db_url]) }
  let(:do_job) { Job.create_from_json(build(:json_dig_obj_file_job),
                       :repo_id => repo.id,
                       :user => create_nobody_user) }
  let(:report) { DigitalObjectFileVersionsReport.new({:repo_id => repo.id},
                                do_job,
                                datab) }
  it 'returns the correct fields for the digital object file versions report' do
    puts report.query.inspect
    expect(report.query.first.keys.length).to eq(4)
    expect(report.query.first).to have_key(:digitalObjectId)
    expect(report.query.first).to have_key(:repo_id)
    expect(report.query.first).to have_key(:identifier)
    expect(report.query.first).to have_key(:title)
  end
  it 'has the correct template name' do
    expect(report.template).to eq('digital_object_file_versions_report.erb')
  end
  xit 'returns the correct number of values' do
  end
end
