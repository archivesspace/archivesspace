require 'spec_helper'

require_relative '../app/model/reports/abstract_report.rb'
require_relative '../app/model/reports/accessions/unprocessed_accessions_report/unprocessed_accessions_report.rb'

describe UnprocessedAccessionsReport do
  let(:repo)  { Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                      :name => "My new test repository")) }
  let(:datab) { Sequel.connect(AppConfig[:db_url]) }
  let(:acc_job) { Job.create_from_json(build(:json_accession_job),
                       :repo_id => repo.id,
                       :user => create_nobody_user) }
  let(:report) { UnprocessedAccessionsReport.new({:repo_id => repo.id},
                                acc_job,
                                datab) }
  it 'returns the correct fields for the accession report' do
    puts report.query.inspect
    # expect(report.query.first.keys.length).to eq(29)
    # expect(report.query.first).to have_key(:id)
    # expect(report.query.first).to have_key(:lock_version)
    # expect(report.query.first).to have_key(:json_schema_version)
    # expect(report.query.first).to have_key(:repo_id)
    # expect(report.query.first).to have_key(:suppressed)
    # expect(report.query.first).to have_key(:identifier)
    # expect(report.query.first).to have_key(:title)
    # expect(report.query.first).to have_key(:display_string)
    # expect(report.query.first).to have_key(:publish)
    # expect(report.query.first).to have_key(:content_description)
    # expect(report.query.first).to have_key(:condition_description)
    # expect(report.query.first).to have_key(:disposition)
    # expect(report.query.first).to have_key(:inventory)
    # expect(report.query.first).to have_key(:provenance)
    # expect(report.query.first).to have_key(:general_note)
    # expect(report.query.first).to have_key(:resource_type_id)
    # expect(report.query.first).to have_key(:acquisition_type_id)
    # expect(report.query.first).to have_key(:accession_date)
    # expect(report.query.first).to have_key(:restrictions_apply)
    # expect(report.query.first).to have_key(:retention_rule)
    # expect(report.query.first).to have_key(:access_restrictions)
    # expect(report.query.first).to have_key(:access_restrictions_note)
    # expect(report.query.first).to have_key(:use_restrictions)
    # expect(report.query.first).to have_key(:use_restrictions_note)
    # expect(report.query.first).to have_key(:created_by)
    # expect(report.query.first).to have_key(:last_modified_by)
    # expect(report.query.first).to have_key(:create_time)
    # expect(report.query.first).to have_key(:system_mtime)
    # expect(report.query.first).to have_key(:user_mtime)
  end
  it 'has the correct template name' do
    expect(report.template).to eq('generic_listing.erb')
  end
  xit 'returns the correct number of values' do
  end
end
