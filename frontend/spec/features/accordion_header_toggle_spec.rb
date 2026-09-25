# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Read-only accordion header toggles', js: true do
  before(:all) do
    @repository = create(:repo, repo_code: "accordion_header_toggle_#{Time.now.to_i}")
    set_repo(@repository)
  end

  before(:each) do
    login_admin
    select_repository(@repository)
  end

  describe 'agent name forms (summary and badges)' do
    let!(:agent) { create(:agent_person) }
    let(:readonly_page_path) { "/agents/agent_person/#{agent.id}" }
    let(:accordion_selector) { '#agent_name_accordion' }
    let(:panel_id) { 'agent_name_0' }

    include_examples 'read-only accordion header toggle'
  end

  describe 'accession dates (multi-column header)' do
    let!(:accession) do
      create(:accession,
             dates: [build(:json_date, expression: 'Accordion test date expression')])
    end
    let(:readonly_page_path) { "/accessions/#{accession.id}" }
    let(:accordion_selector) { '#accession_dates__accordion' }
    let(:panel_id) { 'accession_dates__date_0' }

    include_examples 'read-only accordion header toggle'
  end

  describe 'agent places (plain-text subject summary in header)' do
    let!(:agent) { create(:agent_person, agent_places: [build(:json_agent_place)]) }
    let(:readonly_page_path) { "/agents/agent_person/#{agent.id}" }
    let(:accordion_selector) { '#agent_person_agent_place_accordion' }
    let(:panel_id) { 'agent_person_agent_place_agent_place_0' }

    include_examples 'read-only accordion header toggle'

    before do
      visit readonly_page_path
    end

    it 'does not nest token buttons in the accordion header' do
      within("#{accordion_selector} button.accordion-toggle[aria-controls='#{panel_id}']") do
        expect(page).to have_no_css('button.token')
        expect(page).to have_css('.subject-inline-abbr')
      end
    end

    it 'shows a linked token when the panel is expanded' do
      find("#{accordion_selector} button.accordion-toggle[aria-controls='#{panel_id}']").click
      within("##{panel_id}") do
        expect(page).to have_css('a.token', minimum: 1)
      end
    end
  end

  describe 'digital object file versions (wide summary header)' do
    let(:now) { Time.now.to_i }
    let(:file_uri) { "/accordion/do/#{now}.txt" }
    let(:readonly_page_path) { "/digital_objects/#{digital_object.id}" }
    let(:accordion_selector) { '#digital_object_file_versions__accordion' }
    let(:panel_id) { 'digital_object_file_versions__file_version_0' }
    let!(:digital_object) do
      create(:digital_object,
             title: "Accordion DO #{now}",
             file_versions: [build(:file_version, file_uri: file_uri)])
    end

    include_examples 'read-only accordion header toggle'
  end
end
