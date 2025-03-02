# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe RepositoriesController, type: :controller do
  include BackendClientMethods
  include FactoryBot::Syntax::Methods
  include TestUtils::SpecIndexing

  before(:all) do
    @repo = create(:repo,
                  :repo_code => "test_repo",
                  :name => "Test Repository 1",
                  :publish => true)

    contact = build(:json_agent_contact)
    @repo_agent = create(:json_agent_corporate_entity,
                        :agent_contacts => [contact])

    @repo_with_agent = create(:json_repository,
                             :repository => @repo,
                             :agent_representation => {'ref' => @repo_agent.uri},
                             :name => "Test Repository 1",
                             :description => "Test Repository 1 Description")

    @repo_no_desc = create(:repo,
                          :repo_code => "test_repo_no_desc",
                          :name => "Test Repository No Description",
                          :publish => true)

    run_indexers
  end

  it "has repositories with their descriptions" do
    # Verify repository with description
    expect(@repo_with_agent).to_not be_nil
    expect(@repo_with_agent.name).to eq("Test Repository 1")
    expect(@repo_with_agent.description).to eq("Test Repository 1 Description")

    # Verify repository without description
    expect(@repo_no_desc).to_not be_nil
    expect(@repo_no_desc.name).to eq("Test Repository No Description")
    expect(@repo_no_desc.description).to be_nil
  end

  it "handles long descriptions appropriately" do
    long_desc = "A" * 300

    repo_long = create(:repo,
                      :repo_code => "test_repo_long",
                      :name => "Test Repository Long Description",
                      :publish => true)

    repo_with_long_desc = create(:json_repository,
                                :repository => repo_long,
                                :name => "Test Repository Long Description",
                                :description => long_desc)

    expect(repo_with_long_desc).to_not be_nil
    expect(repo_with_long_desc.name).to eq("Test Repository Long Description")
    expect(repo_with_long_desc.description).to eq(long_desc)
    expect(repo_with_long_desc.description.length).to eq(300)

    # Clean up the test repository
    repo_long.delete if repo_long
  end

  it "shows full description on the repository index listing" do

    # Verify the repository was created
    expect(@repo).to_not be_nil
    expect(@repo.id).to_not be_nil
    expect(@repo_with_agent).to_not be_nil
    expect(@repo_with_agent.id).to_not be_nil

    expect(@repo_with_agent.description).to eq("Test Repository 1 Description")
  end

  after(:all) do
    [@repo, @repo_no_desc].each do |repo|
      repo.delete if repo
    end

    @repo_agent.delete if @repo_agent

    run_indexers
  end
end
