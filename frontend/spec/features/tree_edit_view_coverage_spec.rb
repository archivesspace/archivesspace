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

      # Overrides the shared context's bare child so the duplicate carries
      # subrecords and links that could plausibly be shared with the original.
      let(:child_record) do
        create(
          :archival_object,
          title: "Child #{now}",
          resource: { ref: root_record.uri },
          component_id: "component-#{now}",
          dates: [build(:date), build(:date)],
          extents: [build(:extent)],
          notes: [build(:json_note_multipart), build(:json_note_singlepart)],
          external_documents: [build(:json_external_document)],
          rights_statements: [build(:json_rights_statement)],
          linked_agents: [{ ref: create(:agent_person).uri, role: 'creator' }],
          accession_links: [{ ref: create(:accession).uri }],
          subjects: [{ ref: create(:subject).uri }],
          instances: [
            { instance_type: 'digital_object', digital_object: { ref: create(:digital_object, title: "Digital Object #{now}").uri } }
          ]
        )
      end

      ROOT_CHILD_SELECTOR = '#infinite-tree-container .root.node > .node-children > li.node'

      before do
        visit edit_path
        wait_for_infinite_tree_loaded
      end

      def root_child_titles
        expect(page).to have_css(ROOT_CHILD_SELECTOR, minimum: 1)

        page
          .all("#{ROOT_CHILD_SELECTOR} > .node-row .record-title", visible: :all)
          .map { |title| title.text(:all).strip }
      end

      def root_child_index_for(title)
        root_child_titles.index { |label| label == title || label.start_with?("#{title}, ") }
      end

      def expect_form_to_have_values_copied_from(original)
        within '#infinite-tree-record-pane' do
          aggregate_failures do
            expect(find('#archival_object_component_id_').value).to eq original.component_id
            expect(find('#archival_object_level_').value).to eq original.level
            {
              '#archival_object_lang_materials_ [data-object-name="lang_material"]' => original.lang_materials,
              '#archival_object_dates_ [data-object-name="date"]' => original.dates,
              '#archival_object_extents_ [data-object-name="extent"]' => original.extents,
              '#archival_object_linked_agents_ [data-object-name="linked_agent"]' => original.linked_agents,
              '#archival_object_accession_links_ [data-object-name="accession_link"]' => original.accession_links,
              '#archival_object_subjects_ [data-object-name="subject"]' => original.subjects,
              '#notes [data-object-name="note"]' => original.notes,
              '#archival_object_external_documents_ [data-object-name="external_document"]' => original.external_documents,
              '#archival_object_rights_statements_ [data-object-name="rights_statement"]' => original.rights_statements
            }.each do |selector, subrecords|
              expect(page).to have_css(selector, count: subrecords.length)
            end
            expect(page).to have_no_css('#archival_object_instances_ [data-object-name="instance"]')
          end
        end
      end

      it 'is placed after its original and survives the original being deleted' do
        duplicate_title = "[Duplicated] #{ao.title}"

        select_tree_row_by_id(ao)
        click_infinite_tree_toolbar_add_duplicate

        expect(page).to have_css('.alert.alert-success.with-hide-alert', text: /duplicated from/)
        expect(page.current_url).to include('#new')

        fill_and_save_new_child_record(
          title: duplicate_title,
          form_prefix: child_form_prefix
        )

        expect(page).to have_css('#infinite-tree-container .record-title', text: duplicate_title)

        visit edit_path
        wait_for_infinite_tree_loaded

        original_index = root_child_index_for(ao.title)
        duplicate_index = root_child_index_for(duplicate_title)
        aggregate_failures do
          expect(original_index).not_to be_nil
          expect(duplicate_index).to eq(original_index + 1)
        end

        select_tree_row_by_id(ao)
        wait_for_infinite_tree_inline_edit_form(form_prefix: child_form_prefix)
        within '#infinite-tree-record-pane' do
          expect(page).to have_css('h2', text: ao.title)
          click_on 'Delete'
        end
        within '#confirmChangesModal' do
          click_on 'Delete'
        end
        expect(page).to have_no_css("#infinite-tree-container li##{infinite_tree_node_id_for(ao)}", visible: :all)

        visit edit_path
        wait_for_infinite_tree_loaded

        aggregate_failures do
          expect(root_child_index_for(duplicate_title)).not_to be_nil
          expect(root_child_index_for(ao.title)).to be_nil
        end

        within '#infinite-tree-container' do
          click_link duplicate_title
        end
        wait_for_infinite_tree_inline_edit_form(form_prefix: child_form_prefix)
        within '#infinite-tree-record-pane' do
          expect(page).to have_field('archival_object_title_', with: duplicate_title)
        end
        expect_form_to_have_values_copied_from(ao)
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
