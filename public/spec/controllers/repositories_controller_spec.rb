# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe RepositoriesController, type: :controller do
  include BackendClientMethods
  include SpecHelperMethods
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

    run_all_indexers
  end

  it "displays repositories with their descriptions in the index" do
    get :index
    expect(response).to have_http_status(200)
    expect(assigns(:json)).to be_instance_of(Array)

    html = Nokogiri::HTML(response.body)

    repo_section = html.css(".recordrow").find { |node| node.text.include?("Test Repository 1") }
    expect(repo_section).to be_present
    expect(repo_section.css(".repository-description")).to be_present
    expect(repo_section.css(".repository-description .text-wrap").text).to include("Test Repository 1 Description")

    repo_no_desc_section = html.css(".recordrow").find { |node| node.text.include?("Test Repository No Description") }
    expect(repo_no_desc_section).to be_present
    expect(repo_no_desc_section.css(".repository-description")).to be_empty
  end

  it "truncates long descriptions in the index view" do
    long_desc = "A" * 300

    repo_long = create(:repo,
                      :repo_code => "test_repo_long",
                      :name => "Test Repository Long Description",
                      :publish => true)

    repo_with_long_desc = create(:json_repository,
                                :repository => repo_long,
                                :name => "Test Repository Long Description",
                                :description => long_desc)

    run_all_indexers

    get :index
    html = Nokogiri::HTML(response.body)

    repo_section = html.css(".recordrow").find { |node| node.text.include?("Test Repository Long Description") }
    expect(repo_section).to be_present

    desc_text = repo_section.css(".repository-description .text-wrap").text
    expect(desc_text.length).to be < long_desc.length
    expect(desc_text).to end_with("...")
  end

  it "shows full description on the repository show page" do
    get :show, params: { id: @repo.id }
    expect(response).to have_http_status(200)

    html = Nokogiri::HTML(response.body)
    desc_section = html.css(".description")
    expect(desc_section).to be_present
    expect(desc_section.text).to include("Test Repository 1 Description")
  end

  after(:all) do
    [@repo, @repo_no_desc].each do |repo|
      repo.delete if repo
    end

    @repo_agent.delete if @repo_agent

    run_all_indexers
  end
end
