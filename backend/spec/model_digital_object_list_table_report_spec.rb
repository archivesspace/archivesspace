require 'spec_helper'

describe DigitalObjectListTableReport do
  let(:repo)  { Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                      :name => "My new test repository")) }
  let(:datab) { Sequel.connect(AppConfig[:db_url]) }
  let(:do_job) { Job.create_from_json(build(:json_dig_obj_file_job),
                       :repo_id => repo.id,
                       :user => create_nobody_user) }
  let(:report) { DigitalObjectListTableReport.new({:repo_id => repo.id},
                                do_job,
                                datab) }
  it 'returns the correct fields for the digital object file versions report' do
    expect(report.query.first.keys.length).to eq(7)
    expect(report.query.first).to have_key(:id)
    expect(report.query.first).to have_key(:repoId)
    expect(report.query.first).to have_key(:identifier)
    expect(report.query.first).to have_key(:title)
    expect(report.query.first).to have_key(:objectType)
    expect(report.query.first).to have_key(:dateExpression)
    expect(report.query.first).to have_key(:resourceIdentifier)
  end
  it 'has the correct template name' do
    expect(report.template).to eq('generic_listing.erb')
  end
  xit 'returns the correct number of values' do
  end
end
