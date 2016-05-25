require 'spec_helper'

describe 'RepositoryReport model' do
  it "returns a report with a repositories data" do
    
    repo = Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                        :name => "My new test repository"))
    report = RepositoryReport.new({:repo_id => repo.id},
                                  Job.create_from_json(build(:json_job),
                                                       :repo_id => repo.id,
                                                       :user => create_nobody_user))
    report.to_enum.first[:repo_code].should eq(repo.repo_code)
    report.to_enum.first[:name].should eq(repo.name)
     
  end
end
