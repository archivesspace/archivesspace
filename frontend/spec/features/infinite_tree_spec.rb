require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree', js: true do
  let(:now) { Time.now.to_i }
  let(:repo) { create(:repo, repo_code: "resources_test_#{now}") }
  let(:resource) { create(:resource, title: "Resource #{now}") }
  let(:ao) { create(:archival_object, resource: { 'ref' => resource.uri }, title: "Archival Object #{now}") }
  let(:display_identifiers) { false }

  before(:each) do
    set_repo(repo)
    login_admin
    select_repository(repo)
    ao

    run_indexer
  end

  subject(:tree) do
    visit "/resources/#{resource.id}"
    wait_for_ajax
    find('.infinite-tree')
  end

  before(:each) do
    allow(AppConfig).to receive(:[]).and_call_original
    allow(AppConfig).to receive(:[])
      .with(:display_identifiers_in_largetree_container)
      .and_return(display_identifiers)
  end

  shared_examples 'renders base columns' do
    it 'renders the base columns' do
      aggregate_failures do
        expect(tree).to have_css('[data-column="title"]', visible: true)
        expect(tree).to have_css('[data-column="level"]', visible: :all)
        expect(tree).to have_css('[data-column="type"]', visible: :all)
        expect(tree).to have_css('[data-column="container"]', visible: :all)
      end
    end
  end

  shared_examples 'identifier column visible' do
    it 'shows the identifier column' do
      expect(tree).to have_css('[data-column="identifier"]', visible: :all)
    end
  end

  shared_examples 'identifier column hidden' do
    it 'does not show the identifier column' do
      expect(tree).not_to have_css('[data-column="identifier"]', visible: :all)
    end
  end

  context 'on the resources show view' do
    describe 'columns' do
      context 'when AppConfig[:display_identifiers_in_largetree_container] is false' do
        let(:display_identifiers) { false }

        include_examples 'renders base columns'
        include_examples 'identifier column hidden'
      end

      context 'when AppConfig[:display_identifiers_in_largetree_container] is true' do
        let(:display_identifiers) { true }

        include_examples 'renders base columns'
        include_examples 'identifier column visible'
      end
    end

    describe 'suppressed badge' do
      let!(:suppressed_ao) do
        create(
          :archival_object,
          resource: { 'ref' => resource.uri },
          title: "Suppressed AO #{now}"
        ).tap { |obj| obj.set_suppressed(true) }
      end

      it 'is shown only for suppressed records' do
        visit "/resources/#{resource.id}"
        badge_selector = '#infinite-tree-container .record-title .badge'
        badge = find(badge_selector, text: 'Suppressed', match: :first)
        badge_parent = badge.find(:xpath, '..')

        expect(page).to have_css(badge_selector, text: 'Suppressed', count: 1)
        expect(badge_parent['title']).to eq(suppressed_ao.title)
      end
    end

    describe 'mixed content in title column' do
      let(:resource) do
        create(
          :resource,
          title: 'This is <emph>a mixed content</emph> title'
        )
      end

      let!(:mixed_content_ao) do
        create(
          :archival_object,
          resource: { 'ref' => resource.uri },
          title: 'This is <emph render="italic">another mixed content</emph> title'
        )
      end

      let!(:plain_ao) do
        create(
          :archival_object,
          resource: { 'ref' => resource.uri },
          title: 'This is not a mixed content title'
        )
      end

      let(:allow_mixed_content_title_fields) { true }

      before(:each) do
        allow(AppConfig)
          .to receive(:[])
          .with(:allow_mixed_content_title_fields)
          .and_return(allow_mixed_content_title_fields)
      end

      it 'renders titles with mixed content appropriately' do
        tree

        resource_node = find("#resource_#{resource.id}")
        expect(resource_node).to have_css('.node-body[title="This is a mixed content title"]')
        resource_mixed_span = resource_node.find('.node-row span.emph.render-none')
        expect(resource_mixed_span).to have_text('a mixed content')

        ao1_node = find("#archival_object_#{mixed_content_ao.id}")
        expect(ao1_node).to have_css('.node-row > .node-body[title="This is another mixed content title"]')
        ao1_mixed_span = ao1_node.find('.node-row span.emph.render-italic')
        expect(ao1_mixed_span).to have_text('another mixed content')

        ao2_node = find("#archival_object_#{plain_ao.id}")
        ao2_title = ao2_node.find('.node-row .record-title')
        expect(ao2_title).not_to have_css('span')
        expect(ao2_title).to have_text('This is not a mixed content title')
      end
    end
  end
end
