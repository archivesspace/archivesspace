# frozen_string_literal: true


RSpec.shared_examples 'entering inline create and cancelling' do |config|
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

RSpec.shared_examples 'saving inline creates with Save and Save +1' do |config|
  let(:now) { Time.now.to_i }
  let(:repo) { create(:repo, repo_code: "itree_inline_save_#{config[:root_type]}_#{now}") }
  let(:root_record) { create(config[:root_factory], title: "Root #{now}") }
  let(:child_record) do
    create(
      config[:child_factory],
      title: "Child #{now}",
      config[:root_relationship_key] => { ref: root_record.uri }
    )
  end
  let(:edit_path) { "/#{config[:root_type]}s/#{root_record.id}/edit" }
  let(:root_hash) { "#tree::#{config[:root_type]}_#{root_record.id}" }
  let(:child_record_hash) { "#tree::#{config[:child_type]}_#{child_record.id}" }
  let(:child_form_prefix) { config[:child_type] }

  before do
    set_repo(repo)
    login_admin
    select_repository(repo)
    child_record
    run_indexer
  end

  describe 'plain Save from Add Child' do
    before do
      visit "#{edit_path}#{root_hash}"
      wait_for_ajax
      wait_for_infinite_tree_pane_ready
      install_inline_create_submit_capture
      click_infinite_tree_toolbar_add_child
    end

    it 'creates the record, rebuilds the tree, and shows the success flash' do
      child_title = "Saved Child #{now}"
      fill_valid_inline_child_fields(child_type: config[:child_type], title: child_title)

      save_label = I18n.t("#{child_form_prefix}._frontend.action.save")
      find('button', text: save_label, match: :first).click
      wait_for_ajax
      wait_for_infinite_tree_pane_ready

      saved_id = saved_child_id_from_pane
      submit_detail = last_record_pane_submit_success_detail

      aggregate_failures do
        expect(submit_detail['created']).to be(true)
        expect(submit_detail['plusOne']).to be(false)
        expect(last_inline_create_submit_detail['plusOne']).to be(false)

        expect(page).to have_css(
          "#infinite-tree-container li##{child_form_prefix}_#{saved_id}.current",
          visible: :all
        )
        expect(page).to have_no_css(
          "li##{child_form_prefix}_new.js-itree-synthetic-new",
          visible: :all
        )
        expect(page.current_url).to include("#tree::#{child_form_prefix}_#{saved_id}")

        within('#infinite-tree-record-pane') do
          expect(page).to have_no_css('#createPlusOne')
          expect(page).to have_css(
            '.alert.alert-success.with-hide-alert',
            text: config[:expected_plain_save_flash].call(child_title, root_record.title)
          )
        end
      end
    end
  end

  describe 'invalid Save +1' do
    before do
      visit "#{edit_path}#{root_hash}"
      wait_for_ajax
      wait_for_infinite_tree_pane_ready
      install_inline_create_submit_capture
      click_infinite_tree_toolbar_add_child
    end

    it 'keeps the new form, synthetic row, and validation errors without advancing' do
      send(config[:fill_invalid_fields], now)

      click_infinite_tree_create_plus_one

      aggregate_failures do
        expect(page).to have_css(
          "li##{child_form_prefix}_new.js-itree-synthetic-new",
          visible: :all
        )
        expect(page.current_url).to include('#new')

        within('#infinite-tree-record-pane') do
          expect(page).to have_css("##{child_form_prefix}_form")
          expect(page).to have_css('.error')
          expect(page).to have_css('#createPlusOne')
        end

        if config[:expected_validation_pattern]
          expect(page).to have_css(
            '.alert.alert-danger.with-hide-alert',
            text: config[:expected_validation_pattern]
          )
        end
      end
    end
  end

  describe 'Save +1 from Add Child' do
    before do
      visit "#{edit_path}#{root_hash}"
      wait_for_ajax
      wait_for_infinite_tree_pane_ready
      install_inline_create_submit_capture
      click_infinite_tree_toolbar_add_child
    end

    it 'saves the record and opens a blank sibling new form with plus-one controls' do
      child_title = "Plus One Child #{now}"
      fill_valid_inline_child_fields(child_type: config[:child_type], title: child_title)

      click_infinite_tree_create_plus_one

      submit_detail = last_record_pane_submit_success_detail
      saved_node_id = infinite_tree_node_id_for_uri(submit_detail['uri'])

      aggregate_failures do
        expect(submit_detail['created']).to be(true)
        expect(submit_detail['plusOne']).to be(true)
        expect(last_inline_create_submit_detail['plusOne']).to be(true)

        within('#infinite-tree-container') do
          expect(page).to have_css(
            ".node", text: /#{Regexp.escape(child_title)}/
          )
          expect(page).to have_css(
            "#infinite-tree-container li##{saved_node_id} + li##{child_form_prefix}_new.js-itree-synthetic-new"
          )
        end

        within('#infinite-tree-record-pane') do
          expect(page).to have_css("##{child_form_prefix}_form")
          expect(page).to have_css('#createPlusOne')
          expect(page).to have_css('.createPlusOneBtn')
        end

        expect(page.current_url).to include('#new')
      end
    end
  end

  describe 'consecutive Save +1' do
    before do
      visit "#{edit_path}#{root_hash}"
      wait_for_ajax
      wait_for_infinite_tree_pane_ready
      click_infinite_tree_toolbar_add_child
    end

    it 'creates multiple sibling records in sequence' do
      first_title = "First Plus One #{now}"
      fill_valid_inline_child_fields(child_type: config[:child_type], title: first_title)
      click_infinite_tree_create_plus_one

      expect(page).to have_content(
        config[:expected_plain_save_flash].call(first_title, root_record.title)
      )

      second_title = "Second Plus One #{now}"
      fill_valid_inline_child_fields(child_type: config[:child_type], title: second_title)
      click_infinite_tree_create_plus_one

      aggregate_failures do
        expect(page).to have_content(
          config[:expected_plain_save_flash].call(second_title, root_record.title)
        )

        within('#infinite-tree-container') do
          expect(page).to have_css('.node', text: /#{Regexp.escape(first_title)}/)
          expect(page).to have_css('.node', text: /#{Regexp.escape(second_title)}/)
          expect(page).to have_css("li##{child_form_prefix}_new.js-itree-synthetic-new")
        end

        within('#infinite-tree-record-pane') do
          expect(page).to have_css("##{child_form_prefix}_form")
          expect(page).to have_css('#createPlusOne')
        end
      end
    end
  end

  describe 'consecutive inline create after plain Save' do
    it 'Add Sibling uses the saved node as anchor on the second create without re-selection' do
      visit "#{edit_path}#{child_record_hash}"
      wait_for_ajax
      click_infinite_tree_toolbar_add_sibling

      sibling_title = "First Sibling #{now}"
      fill_valid_inline_child_fields(child_type: config[:child_type], title: sibling_title)

      save_label = I18n.t("#{child_form_prefix}._frontend.action.save")
      find('button', text: save_label, match: :first).click
      wait_for_ajax
      wait_for_infinite_tree_pane_ready

      saved_id = saved_child_id_from_pane

      aggregate_failures 'saved record is current in tree' do
        expect(page).to have_css(
          "#infinite-tree-container li##{child_form_prefix}_#{saved_id}.current",
          visible: :all
        )
      end

      click_infinite_tree_toolbar_add_sibling

      aggregate_failures do
        within('#infinite-tree-container') do
          expect(page).to have_css(
            "#infinite-tree-container li##{child_form_prefix}_#{saved_id} + li##{child_form_prefix}_new"
          )
          expect(page).to have_no_css(
            "#infinite-tree-container li##{infinite_tree_node_id_for(child_record)} + li##{child_form_prefix}_new"
          )
        end
        expect(page.current_url).to include('#new')
        within('#infinite-tree-record-pane') do
          expect(page).to have_css("##{child_form_prefix}_form")
        end
      end
    end

    it 'Add Child uses the saved child as parent on the second create without re-selection' do
      visit "#{edit_path}#{root_hash}"
      wait_for_ajax
      click_infinite_tree_toolbar_add_child

      child_title = "First Child #{now}"
      fill_valid_inline_child_fields(child_type: config[:child_type], title: child_title)

      save_label = I18n.t("#{child_form_prefix}._frontend.action.save")
      find('button', text: save_label, match: :first).click
      wait_for_ajax
      wait_for_infinite_tree_pane_ready

      saved_id = saved_child_id_from_pane

      aggregate_failures 'saved child is current in tree' do
        expect(page).to have_css(
          "#infinite-tree-container li##{child_form_prefix}_#{saved_id}.current",
          visible: :all
        )
      end

      click_infinite_tree_toolbar_add_child

      aggregate_failures do
        within('#infinite-tree-container') do
          expect(page).to have_css(
            "li##{child_form_prefix}_#{saved_id} > ol.node-children li##{child_form_prefix}_new.js-itree-synthetic-new"
          )
        end
        expect(page.current_url).to include('#new')
        within('#infinite-tree-record-pane') do
          expect(page).to have_css("##{child_form_prefix}_form")
        end
      end
    end
  end
end
