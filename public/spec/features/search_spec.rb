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

  describe 'results highlighting' do
    shared_examples 'highlighting search term in title' do
      it 'highlights the search term in the results' do
        expect(result_title.text).to eq searched_record.title
        expect(result_title.find('.searchterm').text).to eq search_term
      end
    end

    matcher :highlight_term_in_title do |term|
      match_unless_raises do |page|
        expect(result_title.text).to eq searched_record.title
        expect(result_title.find('.searchterm').text).to eq term
      end
    end

    matcher :highlight_term_found_in do |label, term|
      match_unless_raises do |page|
        expect(page).to have_xpath "//div[contains(@class, 'recordrow')][h3[contains(., '#{searched_record.title}')]]//div[contains(@class, 'highlighting')][strong[contains(., '#{label}')]]/span[contains(@class, 'searchterm')][contains(., '#{term}')]"
      end
    end

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

    let(:result_title) { find('.recordrow > h3', text: searched_record.title) }
    let(:result_highlights) { all(:xpath, "//div[contains(@class, 'recordrow')][h3[contains(., '#{searched_record.title}')]]//div[contains(@class, 'highlighting')]") }

    before :each do
      set_repo repository
      searched_record

      run_indexers

      visit('/search')

      element = find('#q0')
      element.fill_in with: search_term
      click_on 'Search'
    end

    describe 'in accessions' do
      let(:searched_record) { create(:json_accession, publish: true, title: "Accession Title #{now}") }

      it_behaves_like 'highlighting search term in title'

      context 'when acquisition type contains the search term' do
        let(:searched_record) { create(:json_accession, :with_acquisition_type, publish: true, title: "Accession Title #{now}") }

        let(:search_term) { searched_record.acquisition_type }

        it 'highlights the search term in acquisition type' do
          expect(page).to highlight_term_found_in "Found in Acquisition Type:", search_term
        end
      end
    end

    describe 'in digital objects' do
      let(:searched_record) { create(:digital_object, title: "Digital Object Title #{now}") }

      it_behaves_like 'highlighting search term in title'
    end

    describe 'in resources' do
      let(:searched_record) do
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
      end

      it 'highlights the search term in the results' do
        expect(page).to highlight_term_in_title search_term

        page.all(:xpath, "//div[contains(@class, 'recordrow')][h3[contains(., '#{searched_record.title}')]]//div[contains(@class, 'highlighting')][strong[contains(., 'Found in Identifier:')]]/span[contains(@class, 'searchterm')]").each do |e|
          expect(e.text).to eq(search_term)
        end

        expect(page).to highlight_term_found_in "Found in Creators:", search_term
        expect(page).to highlight_term_found_in "Found in Notes:", search_term
      end
    end
  end
end
