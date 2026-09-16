# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree toolbar inline create entry and cancel', js: true do
  def install_inline_create_fetch_capture
    page.execute_script(<<~JS)
      window.__itreeInlineCreateRequests = [];
      var originalFetch = window.fetch.bind(window);
      window.fetch = function(input, init) {
        var url = typeof input === 'string' ? input : input.url;
        if (url && url.indexOf('/new?') !== -1) {
          window.__itreeInlineCreateRequests.push(url);
        }
        return originalFetch(input, init);
      };
    JS
  end

  def last_inline_create_request_params
    url = page.evaluate_script(
      'window.__itreeInlineCreateRequests[window.__itreeInlineCreateRequests.length - 1]'
    )
    return {} if url.nil? || url.empty?

    uri = URI.parse(url)
    Hash[URI.decode_www_form(uri.query || '')]
  end

  def anchor_tree_position(record)
    page.find(
      "#infinite-tree-container li##{infinite_tree_node_id_for(record)}"
    )['data-tree-position'].to_i
  end

  def anchor_parent_record_id(record)
    page.find(
      "#infinite-tree-container li##{infinite_tree_node_id_for(record)}"
    )['data-tree-parent-record-id']
  end

  shared_examples 'inline create entry and cancel' do |config|
    let(:now) { Time.now.to_i }
    let(:repo) { create(:repo, repo_code: "itree_inline_create_#{config[:root_type]}_#{now}") }
    let(:root_record) { create(config[:root_factory], title: "Root #{now}") }
    let(:child_record) do
      create(
        config[:child_factory],
        title: "Child #{now}",
        config[:root_relationship_key] => { ref: root_record.uri }
      )
    end
    let(:nested_child_record) do
      create(
        config[:child_factory],
        title: "Nested Child #{now}",
        config[:root_relationship_key] => { ref: root_record.uri },
        parent: { ref: child_record.uri }
      )
    end
    let(:edit_path) { "/#{config[:root_type]}s/#{root_record.id}/edit" }
    let(:root_hash) { "#tree::#{config[:root_type]}_#{root_record.id}" }
    let(:child_record_hash) { "#tree::#{config[:child_type]}_#{child_record.id}" }
    let(:nested_child_record_hash) { "#tree::#{config[:child_type]}_#{nested_child_record.id}" }
    let(:root_form_prefix) { config[:root_type] }
    let(:child_form_prefix) { config[:child_type] }

    before do
      set_repo(repo)
      login_admin
      select_repository(repo)
      child_record
      run_indexer
    end

    describe 'Add Child' do
      context 'from the root record' do
        before do
          visit "#{edit_path}#{root_hash}"
          wait_for_ajax
          wait_for_infinite_tree_pane_ready
          expect(page).to have_css("#infinite-tree-record-pane #form_#{root_form_prefix}")
          install_inline_create_fetch_capture
        end

        it 'opens a new child record form with a synthetic tree row' do
          click_infinite_tree_toolbar_add_child

          aggregate_failures do
            params = last_inline_create_request_params
            expect(params['inline']).to eq('true')
            expect(params["#{config[:root_type]}_id"]).to eq(root_record.id.to_s)
            expect(params["#{config[:child_type]}_id"]).to be_nil

            within('#infinite-tree-container') do
              expect(page).to have_css(
                "li##{child_form_prefix}_new.js-itree-synthetic-new.current"
              )
            end
            within('#infinite-tree-record-pane') do
              expect(page).to have_css("##{child_form_prefix}_form")
              expect(page).to have_button(
                I18n.t("#{child_form_prefix}._frontend.action.save"),
                match: :first
              )
            end
            expect(page.current_url).to include('#new')
          end
        end

        it 'returns to the anchor record edit when Cancel is clicked' do
          click_infinite_tree_toolbar_add_child
          cancel_infinite_tree_record_pane_form

          aggregate_failures do
            within('#infinite-tree-record-pane') do
              expect(page).to have_css("#form_#{root_form_prefix}")
              expect(page).to have_css('h2', text: root_record.title)
            end
            expect(page.current_url).to match(%r{#{Regexp.escape(root_hash)}})
            expect(page).to have_css(
              infinite_tree_current_node_selector(root_record),
              visible: :all
            )
            expect(page).to have_no_css(
              "li##{child_form_prefix}_new.js-itree-synthetic-new",
              visible: :all
            )
          end
        end
      end

      context 'from a child record' do
        before do
          nested_child_record
          run_indexer
          visit "#{edit_path}#{nested_child_record_hash}"
          wait_for_ajax
          install_inline_create_fetch_capture
        end

        it 'opens a new child record form with a synthetic tree row' do
          click_infinite_tree_toolbar_add_child

          aggregate_failures do
            params = last_inline_create_request_params
            expect(params['inline']).to eq('true')
            expect(params["#{config[:root_type]}_id"]).to eq(root_record.id.to_s)
            expect(params["#{config[:child_type]}_id"]).to eq(nested_child_record.id.to_s)

            within('#infinite-tree-container') do
              expect(page).to have_css(
                "li##{child_form_prefix}_new.js-itree-synthetic-new.current.indent-level-3"
              )
              expect(page).to have_css('ol.node-children[data-tree-level="3"]')
            end
            within('#infinite-tree-record-pane') do
              expect(page).to have_css("##{child_form_prefix}_form")
            end
            expect(page.current_url).to include('#new')
          end
        end

        it 'returns to the anchor record edit when Cancel is clicked' do
          click_infinite_tree_toolbar_add_child
          cancel_infinite_tree_record_pane_form

          aggregate_failures do
            within('#infinite-tree-record-pane') do
              expect(page).to have_css("#form_#{child_form_prefix}")
              expect(page).to have_css('h2', text: nested_child_record.title)
            end
            expect(page.current_url).to match(
              %r{#{Regexp.escape(nested_child_record_hash)}}
            )
            expect(page).to have_css(
              infinite_tree_current_node_selector(nested_child_record),
              visible: :all
            )
            expect(page).to have_no_css(
              "li##{child_form_prefix}_new.js-itree-synthetic-new",
              visible: :all
            )
          end
        end
      end
    end

    describe 'Add Sibling' do
      before do
        visit "#{edit_path}#{child_record_hash}"
        wait_for_ajax
        install_inline_create_fetch_capture
      end

      it 'opens a new child record form with a synthetic tree row' do
        click_infinite_tree_toolbar_add_sibling

        aggregate_failures do
          params = last_inline_create_request_params
          expect(params['inline']).to eq('true')
          expect(params["#{config[:root_type]}_id"]).to eq(root_record.id.to_s)
          expect(params['position']).to eq((anchor_tree_position(child_record) + 1).to_s)

          parent_id = anchor_parent_record_id(child_record)
          if parent_id
            expect(params["#{config[:child_type]}_id"]).to eq(parent_id)
          else
            expect(params["#{config[:child_type]}_id"]).to be_nil
          end

          within('#infinite-tree-container') do
            expect(page).to have_css(
              "li##{child_form_prefix}_new.js-itree-synthetic-new.current.indent-level-1"
            )
            expect(page).to have_css(
              "#infinite-tree-container li##{infinite_tree_node_id_for(child_record)} + li##{child_form_prefix}_new"
            )
          end
          within('#infinite-tree-record-pane') do
            expect(page).to have_css("##{child_form_prefix}_form")
          end
          expect(page.current_url).to include('#new')
        end
      end

      it 'returns to the anchor record edit when Cancel is clicked' do
        click_infinite_tree_toolbar_add_sibling
        cancel_infinite_tree_record_pane_form

        aggregate_failures do
          within('#infinite-tree-record-pane') do
            expect(page).to have_css("#form_#{child_form_prefix}")
            expect(page).to have_css('h2', text: child_record.title)
          end
          expect(page.current_url).to match(%r{#{Regexp.escape(child_record_hash)}})
          expect(page).to have_css(
            infinite_tree_current_node_selector(child_record),
            visible: :all
          )
          expect(page).to have_no_css(
            "li##{child_form_prefix}_new.js-itree-synthetic-new",
            visible: :all
          )
        end
      end
    end
  end

  context 'Digital Objects' do
    it_behaves_like 'inline create entry and cancel',
                    root_type: 'digital_object',
                    child_type: 'digital_object_component',
                    root_factory: :digital_object,
                    child_factory: :digital_object_component,
                    root_relationship_key: :digital_object
  end

  context 'Classifications' do
    it_behaves_like 'inline create entry and cancel',
                    root_type: 'classification',
                    child_type: 'classification_term',
                    root_factory: :classification,
                    child_factory: :classification_term,
                    root_relationship_key: :classification
  end
end
