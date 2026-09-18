# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree edit view coverage for Digital Objects and Classifications', js: true do
  shared_examples 'infinite tree edit view coverage' do |config|
    let(:now) { Time.now.to_i }
    let(:repo) { create(:repo, repo_code: "itree_edit_coverage_#{config[:root_type]}_#{now}") }
    let(:root_record) { create(config[:root_factory], title: "Root #{now}") }
    let(:child_record) do
      create(
        config[:child_factory],
        title: "Child #{now}",
        config[:root_relationship_key] => { ref: root_record.uri }
      )
    end
    let(:child_record2) do
      create(
        config[:child_factory],
        title: "Second Child #{now}",
        config[:root_relationship_key] => { ref: root_record.uri }
      )
    end
    let(:show_path) { "/#{config[:root_type]}s/#{root_record.id}" }
    let(:edit_path) { "#{show_path}/edit" }
    let(:child_form_prefix) { config[:child_type] }

    before do
      set_repo(repo)
      login_admin
      select_repository(repo)
      child_record
      child_record2
      run_indexer
      visit edit_path
      wait_for_ajax
    end

    describe 'Close Record' do
      it 'lands on the read-only view with the current child record hash' do
        select_tree_row_by_id(child_record)
        expect(page.current_url).to include("#tree::#{config[:child_type]}_#{child_record.id}")

        find('.js-itree-toolbar-finish-editing').click
        wait_for_ajax

        aggregate_failures do
          expect(page.current_url).not_to include('/edit')
          expect(page.current_url).to include(show_path)
          expect(page.current_url).to include("#tree::#{config[:child_type]}_#{child_record.id}")
        end
      end
    end

    describe 'deleting a child record' do
      it 'removes the deleted record from the tree and leaves a coherent pane' do
        select_tree_row_by_id(child_record)
        wait_for_infinite_tree_inline_edit_form(form_prefix: child_form_prefix)

        within '#infinite-tree-record-pane' do
          expect(page).to have_css('h2', text: child_record.title)
          click_on 'Delete'
        end
        within '#confirmChangesModal' do
          click_on 'Delete'
        end
        wait_for_ajax

        aggregate_failures do
          expect(page).to have_no_css(
            "#infinite-tree-container li##{infinite_tree_node_id_for(child_record)}",
            visible: :all
          )
          expect(page).to have_css(
            "#infinite-tree-container li##{infinite_tree_node_id_for(child_record2)}"
          )
        end
      end
    end

    if config[:supports_suppression]
      describe 'suppressed records' do
        let!(:suppressed_child) do
          create(
            config[:child_factory],
            title: "Suppressed Child #{now}",
            config[:root_relationship_key] => { ref: root_record.uri }
          ).tap { |record| record.set_suppressed(true) }
        end

        before do
          run_indexer
          visit edit_path
          wait_for_ajax
        end

        it 'badges only the suppressed record' do
          badges = page.all('#infinite-tree-container .record-title .badge', text: 'Suppressed')

          aggregate_failures do
            expect(badges.length).to eq(1)
            expect(page).to have_css(
              "li.node[data-uri='#{suppressed_child.uri}'] .record-title .badge",
              text: 'Suppressed'
            )
          end
        end
      end
    end

    describe 'the root row in reorder mode' do
      before do
        enable_reorder_mode
        wait_for_reorder_mode_ready
      end

      it 'is not draggable and shows no drag handle' do
        root_row = page.find(
          "#infinite-tree-container li.node.root[data-uri='#{root_record.uri}'] > .node-row"
        )
        child_row = tree_row(child_record.uri)

        aggregate_failures do
          expect(root_row['draggable']).not_to eq('true')
          expect(root_row).to have_no_css('.node-column[data-column="drag-handle"] svg')
          expect(child_row['draggable']).to eq('true')
          expect(child_row).to have_css('.node-column[data-column="drag-handle"] svg', visible: :all)
        end
      end
    end
  end

  context 'Digital Objects' do
    it_behaves_like 'infinite tree edit view coverage',
                    root_type: 'digital_object',
                    child_type: 'digital_object_component',
                    root_factory: :digital_object,
                    child_factory: :digital_object_component,
                    root_relationship_key: :digital_object,
                    supports_suppression: true
  end

  context 'Classifications' do
    it_behaves_like 'infinite tree edit view coverage',
                    root_type: 'classification',
                    child_type: 'classification_term',
                    root_factory: :classification,
                    child_factory: :classification_term,
                    root_relationship_key: :classification,
                    supports_suppression: false
  end
end
