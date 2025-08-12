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
  end
end
