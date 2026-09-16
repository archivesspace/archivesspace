# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree edit view coverage', js: true do
  context 'Resources' do
    it_behaves_like 'covering edit view tree behavior',
                    InfiniteTreeHierarchyConfigs::RESOURCE.merge(supports_suppression: true)

    describe 'a duplicated record' do
      include_context 'infinite tree integration setup'

      let(:edit_path) { "/resources/#{resource.id}/edit" }
      let(:child_form_prefix) { 'archival_object' }

      ROOT_CHILD_SELECTOR = '#infinite-tree-container .root.node > .node-children > li.node'

      before do
        visit edit_path
        wait_for_ajax
      end

      def root_child_titles
        expect(page).to have_css(ROOT_CHILD_SELECTOR, minimum: 1)

        page
          .all("#{ROOT_CHILD_SELECTOR} > .node-row .record-title", visible: :all)
          .map { |title| title.text(:all).strip }
      end

      it 'is placed after its original and survives the original being deleted' do
        duplicate_title = "[Duplicated] #{ao.title}"

        select_tree_row(ao)
        click_infinite_tree_toolbar_add_duplicate

        expect(page).to have_css('.alert.alert-success.with-hide-alert', text: /duplicated from/)
        expect(page.current_url).to include('#new')

        fill_and_save_new_child_record(
          title: duplicate_title,
          form_prefix: child_form_prefix
        )

        expect(page).to have_css('#infinite-tree-container .record-title', text: duplicate_title)

        visit edit_path
        wait_for_ajax

        titles = root_child_titles
        expect(titles).to include(ao.title, duplicate_title)
        expect(titles.index(duplicate_title)).to eq(titles.index(ao.title) + 1)

        select_tree_row(ao)
        wait_for_infinite_tree_inline_edit_form(form_prefix: child_form_prefix)
        within '#infinite-tree-record-pane' do
          expect(page).to have_css('h2', text: ao.title)
          click_on 'Delete'
        end
        within '#confirmChangesModal' do
          click_on 'Delete'
        end
        wait_for_ajax

        visit edit_path
        wait_for_ajax

        aggregate_failures do
          expect(root_child_titles).to include(duplicate_title)
          expect(root_child_titles).not_to include(ao.title)
        end
      end
    end
  end

  context 'Digital Objects' do
    it_behaves_like 'covering edit view tree behavior', InfiniteTreeHierarchyConfigs::DIGITAL_OBJECT
  end

  context 'Classifications' do
    it_behaves_like 'covering edit view tree behavior', InfiniteTreeHierarchyConfigs::CLASSIFICATION
  end
end
