require 'spec_helper'
require 'rails_helper'

describe 'Search', js: true do
  it 'should go to the correct page' do
    visit('/')
    click_link 'Search The Archives'
    expect(current_path).to eq ('/search')
    finished_all_ajax_requests?
    within all('.col-sm-12')[0] do
      expect(page).to have_content('Search The Archives')
    end
  end

  it 'should use an asterisk for a keyword search when no inputs and search button pressed' do
    visit('/search')
    click_on('submit_search')
    expect(page).to have_selector("div[class='searchstatement']", text: "keyword(s): *")
  end

  it "should submit form, not delete row when search row is added and enter pressed in search field" do
    visit('/search')
    click_on('Add a search row')
    find('#q1').native.send_keys(:return)
    expect(page).to have_content('Showing Results')
  end

  it "should sort by identifier on results page" do
    visit('/search')
    click_on('Add a search row')
    find('#q1').native.send_keys(:return)

    find('#sort').select("Identifier (descending)")

    click_on('Sort')

    identifiers_desc = find_all('span.component').to_a

    expect(identifiers_desc[1].text > identifiers_desc[2].text).to be true
    expect(identifiers_desc[2].text > identifiers_desc[3].text).to be true
  end

  context 'when search results include highlighting' do
    let(:now) { now = Time.now.to_i }
    let(:search_term) { "#{now}" }
    let(:repository) do
      create(
        :repo,
        :repo_code => "resource_search_test_#{now}",
        :name => "Repository Title #{now}",
        publish: true
      )
    end

    it 'searches for a term and successfully highlights the search term in the results' do
      set_repo repository

      accession = create(:accession, title: "Accession Title #{now}")
      digital_object = create(:digital_object, title: "Digital Object Title #{now}")

      person_1 = JSONModel(:name_person).new(primary_name: "Linked Agent 1 #{now}", name_order: 'direct')
      linked_agent_1 = create(:agent_person, names: [person_1], publish: true, dates_of_existence: [])

      person_2 = JSONModel(:name_person).new(:primary_name => "Linked Agent 2 #{now}", name_order: 'direct')
      linked_agent_2 = create(:agent_person, names: [person_2], publish: true, dates_of_existence: [])

      resource = create(:resource,
        :title => "Resource Title #{now}",
        :publish => true,
        :finding_aid_language_note => "Finding aid language note #{now}",
        :id_0 => "id_0 #{now}",
        :id_1 => "with spaces #{now}",
        :repository_processing_note => "Processing note #{now}",
        :linked_agents => [
          { 'role' => 'creator', 'ref' => linked_agent_1.uri },
          { 'role' => 'source', 'ref' => linked_agent_2.uri }
        ],
        :notes => [
          build(:json_note_multipart,
            subnotes: [
              build(:json_note_text, publish: true, content: "Note text #{now}"),
              build(:json_note_text, publish: false, content: "Unpublished note text #{now}")
            ])
        ]
      )

      run_indexers

      visit('/search')

      element = find('#q0')
      element.fill_in with: now
      click_on 'Search'

      record_rows = all('.recordrow')

      expect(record_rows.length).to eq 5

      expect(record_rows[0].text).to include "Accession Title #{now}"
      highlighting = record_rows[0].find('.searchterm')
      expect(highlighting.text).to eq "#{now}"

      expect(record_rows[1].text).to include "Resource Title #{now}"
      highlightings = record_rows[1].all('.searchterm')
      expect(highlightings.length).to eq 5
      highlightings.each do |highlighting|
        expect(highlighting.text).to eq "#{now}"
      end

      expect(record_rows[2].text).to include "Linked Agent 1 #{now}"
      highlighting = record_rows[2].find('.searchterm')
      expect(highlighting.text).to eq "#{now}"

      expect(record_rows[3].text).to include "Linked Agent 2 #{now}"
      highlighting = record_rows[3].find('.searchterm')
      expect(highlighting.text).to eq "#{now}"

      expect(record_rows[4].text).to include "Digital Object Title #{now}"
      highlighting = record_rows[4].find('.searchterm')
      expect(highlighting.text).to eq "#{now}"
    end
  end
end
