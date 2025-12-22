require 'spec_helper'
require 'rails_helper'

describe 'Search', js: true do
  it 'should go to the correct page' do
    visit('/')
    click_link 'Search The Archives'
    expect(current_path).to eq ('/search')
    finished_all_ajax_requests?
    within '.search[role="search"]' do
      expect(page).to have_css('h1', text: 'Search The Archives')
    end

    aggregate_failures 'supporting accessibility by not skipping heading levels' do
      expect(page).to be_axe_clean.checking_only :'heading-order'
    end

    aggregate_failures "supporting accessibility with visible labels in the main search form" do
      within "form#advanced_search" do
        expect(page).not_to have_css("label.sr-only")

        expect(page).to have_xpath("//label[@for='q0']")
        expect(page).to have_xpath("//input[@type='text'][@id='q0']")

        expect(page).to have_xpath("//label[@for='limit']")
        expect(page).to have_xpath("//select[@id='limit']")

        expect(page).to have_xpath("//label[@for='field0']")
        expect(page).to have_xpath("//select[@id='field0']")

        expect(page).to have_xpath("//label[@for='from_year0']")
        expect(page).to have_xpath("//input[@id='from_year0']")

        expect(page).to have_xpath("//label[@for='to_year0']")
        expect(page).to have_xpath("//input[@id='to_year0']")

        first('.btn.btn-light.border').click

        expect(page).to have_xpath("//label[@for='op1']")
        expect(page).to have_xpath("//select[@id='op1']")

        expect(page).to have_xpath("//label[@for='field1']")
        expect(page).to have_xpath("//select[@id='field1']")

        expect(page).to have_xpath("//label[@for='from_year1']")
        expect(page).to have_xpath("//input[@id='from_year1']")

        expect(page).to have_xpath("//label[@for='to_year1']")
        expect(page).to have_xpath("//input[@id='to_year1']")
      end
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

  describe 'sorting' do
    describe 'by identifier' do
      context 'descending' do
        it "sorts by identifier on results page" do
          visit('/search?utf8=✓&op%5B%5D=&q%5B%5D=&limit=resource&field%5B%5D=&from_year%5B%5D=&to_year%5B%5D=&commit=Search')

          find('#sort').select("Identifier (descending)")

          click_on('Sort')

          identifiers_desc = find_all('.identifier .component').to_a

          expect(identifiers_desc[1].text.downcase > identifiers_desc[2].text.downcase).to be true
          expect(identifiers_desc[2].text.downcase > identifiers_desc[3].text.downcase).to be true
        end
      end

      context 'ascending' do
        it "sorts by identifier on results page" do
          visit('/search?utf8=✓&op%5B%5D=&q%5B%5D=&limit=resource&field%5B%5D=&from_year%5B%5D=&to_year%5B%5D=&commit=Search')

          find('#sort').select("Identifier (ascending)")

          click_on('Sort')

          identifiers = find_all('.identifier .component').to_a

          expect(identifiers[1].text.downcase < identifiers[2].text.downcase).to be true
          expect(identifiers[2].text.downcase < identifiers[3].text.downcase).to be true
        end
      end
    end

    describe 'by title' do
      context 'without finding aid filing title' do
        let(:now) { Time.now.to_i }

        before(:each) do
          create(:resource,
                 :title => "AAAA #{now}",
                 :id_0 => "AAAA #{now}",
                 :publish => true)

          create(:resource,
                 :title => "BBBB  #{now}",
                 :id_0 => "BBBB #{now}",
                 :publish => true)

          create(:resource,
                 :title => "CCCC  #{now}",
                 :id_0 => "CCCC #{now}",
                 :publish => true)

          create(:resource,
                 :title => "DDDD  #{now}",
                 :publish => true,
                 :id_0 => "DDDD #{now}")

          run_indexers
        end

        context 'descending' do
          it "sorts the results as expected" do
            visit("/search?utf8=✓&op%5B%5D=&q%5B%5D=#{now}&limit=resource&field%5B%5D=&from_year%5B%5D=&to_year%5B%5D=&commit=Search")

            find('#sort').select("Title (descending)")

            click_on('Sort')

            titles_desc = find_all('h2 .record-title').to_a

            expect(titles_desc[1].text.downcase > titles_desc[2].text.downcase).to be true
            expect(titles_desc[2].text.downcase > titles_desc[3].text.downcase).to be true
          end
        end

        context 'ascending' do
          it "sorts the results as expected" do
            visit("/search?utf8=✓&op%5B%5D=&q%5B%5D=#{now}&limit=resource&field%5B%5D=&from_year%5B%5D=&to_year%5B%5D=&commit=Search")

            find('#sort').select("Title (ascending)")

            click_on('Sort')

            titles = find_all('h2 .record-title').to_a

            expect(titles[1].text.downcase < titles[2].text.downcase).to be true
            expect(titles[2].text.downcase < titles[3].text.downcase).to be true
          end
        end
      end

      context 'with finding aid filing title' do
        let(:now) { Time.now.to_i }

        before(:each) do
          create(:resource,
                 :title => "AAAA #{now}",
                 :id_0 => "AAAA #{now}",
                 :publish => true,
                 :finding_aid_filing_title => "ZZZZ")

          create(:resource,
                 :title => "BBBB  #{now}",
                 :id_0 => "BBBB #{now}",
                 :publish => true,
                 :finding_aid_filing_title => "YYYY")

          create(:resource,
                 :title => "CCCC  #{now}",
                 :id_0 => "CCCC #{now}",
                 :publish => true,
                 :finding_aid_filing_title => "XXXX")

          create(:resource,
                 :title => "DDDD  #{now}",
                 :publish => true,
                 :id_0 => "DDDD #{now}",
                 :finding_aid_filing_title => "WWWW")

          run_indexers
        end

        context 'descending' do
          it "sorts the results using the finding aid filing title, instead of the title" do
            visit("/search?utf8=✓&op%5B%5D=&q%5B%5D=#{now}&limit=resource&field%5B%5D=&from_year%5B%5D=&to_year%5B%5D=&commit=Search")

            find('#sort').select("Title (descending)")

            click_on('Sort')

            identifiers = find_all('.identifier .component').to_a

            expect(identifiers[1].text.downcase < identifiers[2].text.downcase).to be true
            expect(identifiers[2].text.downcase < identifiers[3].text.downcase).to be true
          end
        end

        context 'ascending' do
          it "sorts the results using the finding aid filing title, instead of the title" do
            visit("/search?utf8=✓&op%5B%5D=&q%5B%5D=#{now}&limit=resource&field%5B%5D=&from_year%5B%5D=&to_year%5B%5D=&commit=Search")

            find('#sort').select("Title (ascending)")

            click_on('Sort')

            identifiers = find_all('.identifier .component').to_a

            expect(identifiers[1].text.downcase > identifiers[2].text.downcase).to be true
            expect(identifiers[2].text.downcase > identifiers[3].text.downcase).to be true

          end
        end
      end
    end
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
        expect(page).to have_xpath "//div[contains(@class, 'recordrow')][h2[contains(., '#{searched_record.title}')]]//div[contains(@class, 'highlighting')][strong[contains(., '#{label}')]]/span[contains(@class, 'searchterm')][contains(., '#{term}')]"
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

    let(:result_title) { find('.recordrow > h2', text: searched_record.title) }
    let(:result_highlights) { all(:xpath, "//div[contains(@class, 'recordrow')][h2[contains(., '#{searched_record.title}')]]//div[contains(@class, 'highlighting')]") }

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
      context 'when search terms found in title' do
        let(:now) { now = Time.now.to_i }

        let(:searched_record) do
          person_1 = JSONModel(:name_person).new(primary_name: "Linked Agent 1 #{now}", name_order: 'direct')
          linked_agent_1 = create(:agent_person, names: [person_1], publish: true, dates_of_existence: [])

          person_2 = JSONModel(:name_person).new(:primary_name => "Linked Agent 2 #{now}", name_order: 'direct')
          linked_agent_2 = create(:agent_person, names: [person_2], publish: true, dates_of_existence: [])

          create(:resource,
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
                           build(:json_note_text, publish: true, content: "<title>Mixed content</title> note text #{now}"),
                           build(:json_note_text, publish: false, content: "Unpublished note text #{now}")
                         ])
                 ]
                )
        end

        it 'highlights the search term in the results title and found in sections' do
          expect(page).to highlight_term_in_title search_term

          page.all(:xpath, "//div[contains(@class, 'recordrow')][h2[contains(., '#{searched_record.title}')]]//div[contains(@class, 'highlighting')][strong[contains(., 'Found in Identifier:')]]/span[contains(@class, 'searchterm')]").each do |e|
            expect(e.text).to eq(search_term)
          end

          expect(page).to highlight_term_found_in "Found in Creators:", search_term
          expect(page).to highlight_term_found_in "Found in Notes:", search_term
          found_in_notes = page.find('.highlighting', text: 'Found in Notes:')
          expect(found_in_notes).to have_css('span.title', text: "Mixed content")
          expect(found_in_notes).to have_content("Mixed content note text #{now}")
        end
      end

      context 'when search terms found in finding aid filing title only' do
        let(:now) { now = Time.now.to_i }

        let(:search_term) { "Finding aid filing title #{now}" }

        let(:searched_record) do
          person_1 = JSONModel(:name_person).new(primary_name: "Linked Agent 1 #{now}", name_order: 'direct')
          linked_agent_1 = create(:agent_person, names: [person_1], publish: true, dates_of_existence: [])

          person_2 = JSONModel(:name_person).new(:primary_name => "Linked Agent 2 #{now}", name_order: 'direct')
          linked_agent_2 = create(:agent_person, names: [person_2], publish: true, dates_of_existence: [])

          resource = create(:resource,
                            :title => "Resource Title",
                            :publish => true,
                            :finding_aid_filing_title => "Finding aid filing title #{now}",
                            :id_0 => "id_0 #{now}",
                            :id_1 => "with spaces #{now}",
                            :repository_processing_note => "Processing note",
                            :linked_agents => [
                              { 'role' => 'creator', 'ref' => linked_agent_1.uri },
                              { 'role' => 'source', 'ref' => linked_agent_2.uri }
                            ],
                            :notes => [
                              build(:json_note_multipart,
                                    subnotes: [
                                      build(:json_note_text, publish: true, content: "<title>Mixed content</title> note text"),
                                      build(:json_note_text, publish: false, content: "Unpublished note text")
                                    ])
                            ]
                           )
        end

        it 'does not include the record in the search results' do
          expect(find_all('h2 .record-title').to_a).to be_empty
          expect(page).to have_text('No Records Found')
        end
      end
    end
  end
end
