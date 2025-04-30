# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Reorder Mode', js: true do
  before(:all) do
    @now = Time.now.to_i
    @repo = create(:repo, repo_code: "reorder_mode_test_#{@now}")
    set_repo(@repo)

    @classification = create(:classification, title: "Classification #{@now}")
    @classification_term = create(:classification_term, classification: { ref: @classification.uri }, title: "Classification Term #{@now}")
    @classification_term2 = create(:classification_term, classification: { ref: @classification.uri }, title: "Classification Term 2 #{@now}")
    @classification_term3 = create(:classification_term,
      classification: { ref: @classification.uri },
      parent: { ref: @classification_term2.uri },
      title: "Classification Term 3 #{@now}"
    )
    @classification_term4 = create(:classification_term,
      classification: { ref: @classification.uri },
      parent: { ref: @classification_term3.uri },
      title: "Classification Term 4 #{@now}"
    )

    @digital_object = create(:digital_object, title: "Digital Object #{@now}")
    @doc = create(:digital_object_component, digital_object: { ref: @digital_object.uri }, title: "Digital Object Component #{@now}")
    @doc2 = create(:digital_object_component, digital_object: { ref: @digital_object.uri }, title: "Digital Object Component 2 #{@now}")
    @doc3 = create(:digital_object_component, digital_object: { ref: @digital_object.uri }, parent: { ref: @doc2.uri }, title: "Digital Object Component 3 #{@now}")

    @resource = create(:resource, title: "Resource #{@now}")
    @ao = create(:archival_object, resource: { ref: @resource.uri }, title: "Archival Object #{@now}")
    @ao2 = create(:archival_object, resource: { ref: @resource.uri }, title: "Archival Object 2 #{@now}")
    @ao3 = create(:archival_object, resource: { ref: @resource.uri }, parent: { ref: @ao2.uri }, title: "Archival Object 3 #{@now}")

    run_indexer
  end

  before(:each) do
    login_admin
    select_repository(@repo)
  end

  describe 'can be enabled' do
    def test_enable(type, parent)
      visit "/#{type}/#{parent.id}/edit"
      wait_for_ajax
      expect(page).to have_css '#tree-container:not(.drag-enabled)'
      click_on "Enable Reorder Mode"
      wait_for_ajax
      expect(page).to have_css '#tree-container.drag-enabled'
    end

    it 'for classifications' do
      test_enable('classifications', @classification)
    end

    it 'for digital objects' do
      test_enable('digital_objects', @digital_object)
    end

    it 'for resources' do
      test_enable('resources', @resource)
    end
  end

  describe 'interface' do
    describe 'toolbar' do
      describe 'contains the correct order of buttons' do
        def test_toolbar_order(type, parent)
          visit "/#{type}/#{parent.id}/edit"
          wait_for_ajax
          expect(page).to have_css '#tree-container:not(.drag-enabled)'
          click_on "Enable Reorder Mode"
          wait_for_ajax
          toolbar = find('#tree-toolbar')
          expect(toolbar).to have_css '.btn-group:first-child .btn', text: 'Disable Reorder Mode'
          expect(toolbar).to have_css '.btn-group:nth-child(2) .btn:first-child', text: 'Cut'
          expect(toolbar).to have_css '.btn-group:nth-child(2) .btn:last-child', text: 'Paste'
          expect(toolbar).to have_css '.btn-group:nth-child(3) li:first-child', text: 'Drop Before'
          expect(toolbar).to have_css '.btn-group:nth-child(3) li:nth-child(2)', text: 'Drop as Child'
          expect(toolbar).to have_css '.btn-group:nth-child(3) li:last-child', text: 'Drop After'
          expect(toolbar).to have_css '.btn-group:nth-child(4)', visible: false
          expect(toolbar).to have_css '.btn-group:nth-child(5) .btn', text: 'Close Record'
          expect(toolbar).to have_css '.btn-group:nth-child(6)', visible: false
        end

        it 'for classifications' do
          test_toolbar_order('classifications', @classification)
        end

        it 'for digital objects' do
          test_toolbar_order('digital_objects', @digital_object)
        end

        it 'for resources' do
          test_toolbar_order('resources', @resource)
        end
      end
    end

    describe 'tree' do
      context 'root node' do
        describe 'drag handle' do
          describe 'is not visible' do
            def test_drag_handle_not_visible(type, parent)
              visit "/#{type}/#{parent.id}/edit"
              wait_for_ajax
              click_on "Enable Reorder Mode"
              wait_for_ajax
              expect(page).to have_css '.drag-enabled .root-row.current .no-drag-handle'
              expect(page).not_to have_css '.drag-enabled .root-row.current .no-drag-handle svg'
            end

            it 'for classifications' do
              test_drag_handle_not_visible('classifications', @classification)
            end

            it 'for digital objects' do
              test_drag_handle_not_visible('digital_objects', @digital_object)
            end

            it 'for resources' do
              test_drag_handle_not_visible('resources', @resource)
            end
          end
        end
      end

      context 'child nodes' do
        describe 'drag handle' do
          describe 'is visible' do
            def test_drag_handle_visible(type, parent, children)
              child_type = case type
                           when 'resources' then 'archival_object'
                           when 'classifications' then 'classification_term'
                           when 'digital_objects' then 'digital_object_component'
                           end
              visit "/#{type}/#{parent.id}/edit"
              wait_for_ajax
              click_on "Enable Reorder Mode"
              wait_for_ajax
              children.each do |child|
                expect(page).to have_css ".drag-enabled ##{child_type}_#{child.id} .drag-handle svg"
              end
            end

            it 'for classifications' do
              test_drag_handle_visible('classifications', @classification, [@classification_term, @classification_term2])
            end

            it 'for digital objects' do
              test_drag_handle_visible('digital_objects', @digital_object, [@doc, @doc2])
            end

            it 'for resources' do
              test_drag_handle_visible('resources', @resource, [@ao, @ao2])
            end
          end
        end
      end
    end
  end
end
