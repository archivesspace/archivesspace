require 'spec_helper'
require 'rails_helper'

describe 'Document Heading Hierarchy', js: true do
  shared_examples 'a page with correct heading hierarchy' do |headings:|
    it 'has proper heading hierarchy' do
      aggregate_failures do
        headings.each do |level, text|
          expect(page).to have_css("h#{level}", text: text)
        end
        expect(page).to be_axe_clean.checking_only :'heading-order'
      end
    end
  end

  shared_examples 'an index page with proper heading hierarchy' do |h1_pattern:, has_sidebar: false, sidebar_has_h3: false|
    it 'has proper heading hierarchy' do
      aggregate_failures do
        expect(page).to have_css('h1', text: h1_pattern)
        expect(page).to have_css('h2 > a.record-title', minimum: 1)

        if has_sidebar
          within('#filter-sidebar') do
            expect(page).to have_css('h2', text: 'Filter Results')
            if sidebar_has_h3
              expect(page).to have_css('h3', text: 'Additional filters:')
            end
          end
        end

        expect(page).to be_axe_clean.checking_only :'heading-order'
      end
    end
  end

  shared_examples 'a show page with Found in h2 > h3 hierarchy' do |record_type:, resource_count:|
    it 'has proper heading hierarchy with h3 for "Found in" results' do
      h1_text = "#{record_type} #{@now}"
      h2_text = if resource_count == 1
                  'Found in 1 Collection or Record:'
                else
                  'Found in 2 Collections and/or Records:'
                end

      aggregate_failures do
        expect(page).to have_css('h1', text: h1_text)
        expect(page).to have_css('h2', text: h2_text)
        expect(page).to have_css('h3 > a.record-title', count: resource_count)
        expect(page).to have_css('h3 > a.record-title', text: @resource.title)
        if resource_count == 2
          expect(page).to have_css('h3 > a.record-title', text: @resource2.title)
        end
        expect(page).to be_axe_clean.checking_only :'heading-order'
      end
    end
  end

  describe 'Welcome page' do
    before { visit '/' }

    it_behaves_like 'a page with correct heading hierarchy',
      headings: {
        1 => 'Welcome to ArchivesSpace',
        2 => 'Search The Archives'
      }
  end

  describe 'Search page' do
    before { visit '/search' }

    it_behaves_like 'a page with correct heading hierarchy',
      headings: { 1 => 'Search The Archives' }
  end

  describe 'Index pages' do
    REPOSITORIES_PATTERN = /\A\d+\s+Repositor(?:y|ies)\b/
    SHOWING_PATTERN = /\AShowing .+:\s+\d+\s+-\s+\d+\s+of\s+\d+/

    context 'Repositories' do
      before { visit '/repositories' }

      it_behaves_like 'an index page with proper heading hierarchy',
        h1_pattern: REPOSITORIES_PATTERN,
        has_sidebar: false
    end

    context 'Resources' do
      before { visit '/repositories/resources' }

      it_behaves_like 'an index page with proper heading hierarchy',
        h1_pattern: SHOWING_PATTERN,
        has_sidebar: true,
        sidebar_has_h3: true
    end

    context 'Digital Objects' do
      before { visit '/objects?limit=digital_object' }

      it_behaves_like 'an index page with proper heading hierarchy',
        h1_pattern: SHOWING_PATTERN,
        has_sidebar: true,
        sidebar_has_h3: true
    end

    context 'Accessions' do
      before { visit '/accessions' }

      it_behaves_like 'an index page with proper heading hierarchy',
        h1_pattern: SHOWING_PATTERN,
        has_sidebar: false
    end

    context 'Subjects' do
      before { visit '/subjects' }

      it_behaves_like 'an index page with proper heading hierarchy',
        h1_pattern: SHOWING_PATTERN,
        has_sidebar: true,
        sidebar_has_h3: true
    end

    context 'Agents' do
      before { visit '/agents' }

      it_behaves_like 'an index page with proper heading hierarchy',
        h1_pattern: SHOWING_PATTERN,
        has_sidebar: true,
        sidebar_has_h3: true
    end

    context 'Classifications' do
      before { visit '/classifications' }

      it_behaves_like 'an index page with proper heading hierarchy',
        h1_pattern: SHOWING_PATTERN,
        has_sidebar: true,
        sidebar_has_h3: false
    end
  end

  describe 'Show pages with "Found in" sections' do
    before(:all) do
      @now = Time.now.to_i
      @repo = create(:repo, publish: true, repo_code: "found_in_test_#{@now}")
      set_repo @repo
      @subject = create(:subject,
        terms: [build(:term, term: "Subject #{@now}")],
        publish: true
      )
      @agent = create(:agent_person,
        names: [build(:name_person, primary_name: "Agent #{@now}")],
        publish: true
      )
      @classification = create(:classification,
        title: "Classification #{@now}",
        identifier: "TC-#{@now}",
        publish: true
      )
      @resource = create(:resource,
        title: "Resource #{@now}",
        subjects: [{ 'ref' => @subject.uri }],
        linked_agents: [{ 'role' => 'creator', 'ref' => @agent.uri }],
        classifications: [{ 'ref' => @classification.uri }],
        publish: true
      )
      @resource2 = create(:resource,
        title: "Second Resource #{@now}",
        subjects: [{ 'ref' => @subject.uri }],
        publish: true
      )
      run_indexers
    end

    after(:all) do
      @resource2&.delete
      @resource&.delete
      @classification&.delete
      @agent&.delete
      @subject&.delete
      @repo&.delete
    end

    context 'Subject show page' do
      before { visit @subject.uri }

      it_behaves_like 'a show page with Found in h2 > h3 hierarchy',
        record_type: 'Subject',
        resource_count: 2
    end

    context 'Agent show page' do
      before { visit @agent.uri }

      it_behaves_like 'a show page with Found in h2 > h3 hierarchy',
        record_type: 'Agent',
        resource_count: 1
    end

    context 'Classification show page' do
      before { visit @classification.uri }

      it_behaves_like 'a show page with Found in h2 > h3 hierarchy',
        record_type: 'Classification',
        resource_count: 1
    end
  end
end
