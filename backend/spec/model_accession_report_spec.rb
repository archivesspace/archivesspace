require 'spec_helper'

require_relative '../app/model/reports/abstract_report.rb'
require_relative '../app/model/reports/accessions/accession_report/accession_report.rb'

describe AccessionReport do
  it 'runs' do
    puts 'It runs!'
  end
  it 'generates an accession report' do
    repo = Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                        :name => "My new test repository"))

    report = AccessionReport.new({:repo_id => repo.id},
                                  Job.create_from_json(build(:json_job),
                                                       :repo_id => repo.id,
                                                       :user => create_nobody_user),
                                  $testdb)
    puts "#{report.template}"
  end

end
