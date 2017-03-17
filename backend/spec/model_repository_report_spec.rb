require 'spec_helper'

describe 'RepositoryReport model' do
  it "returns a report with repository data" do
    
    repo = Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                        :name => "My new test repository"))

    report = RepositoryReport.new({:repo_id => repo.id},
                                  Job.create_from_json(build(:json_job),
                                                       :repo_id => repo.id,
                                                       :user => create_nobody_user),
                                  $testdb)

    report.to_enum.any? {|row|
      row[:repo_code] == repo.repo_code && row[:name] == repo.name
    }.should be true
  end
end
