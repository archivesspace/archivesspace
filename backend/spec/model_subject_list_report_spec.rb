require 'spec_helper'

describe SubjectListReport do
  let(:repo)  { Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                      :name => "My new test repository")) }
  let(:datab) { Sequel.connect(AppConfig[:db_url]) }
  let(:sub_list_job) { Job.create_from_json(build(:json_subject_list_job),
                       :repo_id => repo.id,
                       :user => create_nobody_user) }
  let(:report) { SubjectListReport.new({:repo_id => repo.id},
                                sub_list_job,
                                datab) }
  it 'returns the correct fields for the subject list report' do
    expect(report.query.first.keys.length).to eq(5)
    expect(report.query.first).to have_key(:subject_id)
    expect(report.query.first).to have_key(:subject_title)
    expect(report.query.first).to have_key(:subject_source_id)
    expect(report.query.first).to have_key(:subject_term_type)
    expect(report.query.first).to have_key(:subject_source)
  end
  it 'has the correct template name' do
    expect(report.template).to eq('generic_listing.erb')
  end
  xit 'returns the correct number of values' do
  end
end
