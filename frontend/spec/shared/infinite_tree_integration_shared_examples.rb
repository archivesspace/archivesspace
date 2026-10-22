# frozen_string_literal: true

# Shared setup and examples for Infinite Tree integration specs.
# Examples are parameterized by view (show vs edit) and scenario.

RSpec.shared_context 'infinite tree integration hierarchy setup' do |config|
  let(:now) { Time.now.to_i }
  before(:all) { @repo = create(:repo, repo_code: "infinite_tree_integration_#{config[:root_type]}_#{Time.now.to_i}_#{SecureRandom.hex(2)}") }
  let(:repo) { @repo }
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
  let(:root_type) { config[:root_type] }
  let(:child_type) { config[:child_type] }
  let(:root_form_prefix) { config[:root_type] }
  let(:child_form_prefix) { config[:child_type] }
  let(:show_path) { "/#{config[:root_type]}s/#{root_record.id}" }
  let(:edit_path) { "#{show_path}/edit" }
  let(:root_hash) { "#tree::#{config[:root_type]}_#{root_record.id}" }
  let(:child_record_hash) { "#tree::#{config[:child_type]}_#{child_record.id}" }
  let(:nested_child_record_hash) { "#tree::#{config[:child_type]}_#{nested_child_record.id}" }
  let(:child_save_label) { I18n.t("#{config[:child_type]}._frontend.action.save") }

  before do
    set_repo(repo)
    login_admin_and_select_repository(repo)
    child_record
  end
end

RSpec.shared_context 'infinite tree integration setup' do
  include_context 'infinite tree integration hierarchy setup',
                  root_type: 'resource',
                  child_type: 'archival_object',
                  root_factory: :resource,
                  child_factory: :archival_object,
                  root_relationship_key: :resource

  # Legacy aliases used by existing Resource-only specs.
  let(:resource) { root_record }
  let(:ao) { child_record }
end

# path_let: symbol for let that returns the path (e.g. :show_path)
# view_type: :show (readonly pane) or :edit (edit form)
RSpec.shared_examples 'adds root hash and displays root on load' do |path_let, view_type|
  it "adds root hash and displays root (#{view_type})" do
    path = send(path_let)
    visit path
    wait_for_infinite_tree_loaded

    aggregate_failures do
      expect(page.current_url).to match(%r{#{Regexp.escape(path)}#tree::#{root_type}_})
      expect(page).to have_css('#infinite-tree-container .root.current')
      expect(page).to have_css(
        '#infinite-tree-container .node.current',
        count: 1,
        visible: :all
      )
      within('#infinite-tree-record-pane') do
        expect(page).to have_css('h2', text: root_record.title)
        case view_type
        when :show
          expect(page).to have_css('.readonly-context')
          expect(page).to have_field('uri', with: root_record.uri)
        when :edit
          expect(page).to have_css("#form_#{root_form_prefix}")
        end
      end
    end
  end
end

# path_let, hash_let, record_let: symbols for lets (e.g. :show_path, :root_hash, :resource)
# edit_form_selector: required when view_type is :edit (e.g. '#form_resource')
RSpec.shared_examples 'keeps hash and displays record on load' do |path_let, hash_let, record_let, view_type, edit_form_selector = nil|
  it "keeps hash and displays record (#{view_type})" do
    path = send(path_let)
    hash = send(hash_let)
    record = send(record_let)
    visit "#{path}#{hash}"
    wait_for_infinite_tree_loaded

    aggregate_failures do
      expect(page.current_url).to match(%r{#{Regexp.escape(path)}#{Regexp.escape(hash)}})
      expect(page).to have_css(infinite_tree_current_node_selector(record))
      expect(page).to have_css(
        '#infinite-tree-container .node.current',
        count: 1,
        visible: :all
      )
      within('#infinite-tree-record-pane') do
        expect(page).to have_css('h2', text: record.title)
        case view_type
        when :show
          expect(page).to have_css('.readonly-context')
          expect(page).to have_field('uri', with: record.uri)
        when :edit
          expect(page).to have_css(edit_form_selector)
        end
      end
    end
  end
end

# Params path_let through expected_hash_let are symbols for lets (e.g. :show_path, :root_hash, :resource, :ao, :ao_hash).
# edit_form_selector: required when view_type is :edit (e.g. '#form_resource').
RSpec.shared_examples 'tree node title click updates pane and URL when no unsaved changes' do |path_let, start_hash_let, start_record_let, node_let, expected_hash_let, view_type, edit_form_selector = nil|
  it "clicking #{node_let} from #{start_record_let} updates pane and URL (#{view_type})" do
    path = send(path_let)
    start_hash = send(start_hash_let)
    node = send(node_let)
    expected_hash = send(expected_hash_let)
    expected_record = node
    visit "#{path}#{start_hash}"
    wait_for_infinite_tree_loaded

    within('#infinite-tree-container') { click_link node.title }
    wait_for_infinite_tree_current_node(node.uri)

    aggregate_failures do
      expect(page.current_url).to match(%r{#{Regexp.escape(expected_hash)}})
      expect(page).to have_css(infinite_tree_current_node_selector(expected_record))
      expect(page).to have_css(
        '#infinite-tree-container .node.current',
        count: 1,
        visible: :all
      )
      within('#infinite-tree-record-pane') do
        expect(page).to have_css('h2', text: expected_record.title)
        case view_type
        when :show
          expect(page).to have_css('.readonly-context')
        when :edit
          expect(page).to have_css(edit_form_selector)
        end
      end
    end
  end
end

RSpec.shared_examples 'navigating the edit view with integrated router and pane' do |config|
  include_context 'infinite tree integration hierarchy setup', config

  describe 'on initial load' do
    context 'when the URL has no record hash' do
      it_behaves_like 'adds root hash and displays root on load', :edit_path, :edit
    end

    context 'when the URL has a valid record hash' do
      it_behaves_like 'keeps hash and displays record on load',
                      :edit_path, :root_hash, :root_record, :edit, "#form_#{config[:root_type]}"
      it_behaves_like 'keeps hash and displays record on load',
                      :edit_path, :child_record_hash, :child_record, :edit, "#form_#{config[:child_type]}"
    end

    context 'when the URL has a hash for a non-existent record' do
      it 'displays the tree root and Record Not Found in the pane' do
        nonexistent_id = child_record.id + 999
        visit "#{edit_path}#tree::#{child_type}_#{nonexistent_id}"
        expect(page).to have_css('#infinite-tree-record-pane h2', text: 'Record Not Found')

        aggregate_failures do
          expect(page).to have_css('#infinite-tree-container .root')
          expect(page).not_to have_css(
            '#infinite-tree-container .current',
            visible: :all
          )
          within('#infinite-tree-record-pane') do
            expect(page).to have_css('h2', text: 'Record Not Found')
            expect(page).to have_text("The record you've tried to access may no longer exist or you may not have permission to view it.")
          end
        end
      end
    end
  end

  describe 'when navigating with no unsaved changes' do
    context 'via tree node click' do
      it_behaves_like 'tree node title click updates pane and URL when no unsaved changes',
                      :edit_path, :root_hash, :root_record, :child_record, :child_record_hash, :edit, "#form_#{config[:child_type]}"
      it_behaves_like 'tree node title click updates pane and URL when no unsaved changes',
                      :edit_path, :child_record_hash, :child_record, :root_record, :root_hash, :edit, "#form_#{config[:root_type]}"
    end

    context 'via record hash change' do
      it 'updates the pane and URL to the target record' do
        visit "#{edit_path}#{root_hash}"
        wait_for_infinite_tree_loaded

        page.execute_script("window.location.hash = 'tree::#{child_type}_#{child_record.id}'")
        wait_for_infinite_tree_current_node(child_record.uri)

        aggregate_failures do
          expect(page.current_url).to match(%r{#{child_record_hash}})
          within('#infinite-tree-record-pane') { expect(page).to have_css('h2', text: child_record.title) }
        end
      end
    end
  end

  describe 'when navigating with unsaved changes' do
    it 'guard shows modal on hash change and reverts the hash' do
      visit "#{edit_path}#{child_record_hash}"
      wait_for_infinite_tree_loaded
      fill_in config[:child_dirty_field], with: 'unsaved change'
      wait_for_infinite_tree_record_pane_dirty

      page.execute_script("window.location.hash = 'tree::#{root_type}_#{root_record.id}'")

      aggregate_failures do
        expect(page).to have_css('#saveYourChangesModal', visible: true)
        expect(page.current_url).to match(%r{#{child_record_hash}})

        within('#saveYourChangesModal') { click_on 'Cancel' }
        expect(page).not_to have_css('#saveYourChangesModal', visible: true)
      end
    end

    it 'guard shows modal on tree title click' do
      visit "#{edit_path}#{child_record_hash}"
      wait_for_infinite_tree_loaded
      fill_in config[:child_dirty_field], with: 'unsaved change'
      wait_for_infinite_tree_record_pane_dirty

      within('#infinite-tree-container') { click_link root_record.title }

      expect(page).to have_css('#saveYourChangesModal', visible: true)
      within('#infinite-tree-record-pane') { expect(page).to have_css('h2', text: child_record.title) }
    end

    describe 'Revert Changes' do
      context 'for root' do
        it 'dismisses unsaved changes and reloads selected root record' do
          visit "#{edit_path}#{root_hash}"
          wait_for_infinite_tree_loaded

          initial_title = find_field(config[:root_dirty_field]).value

          fill_in config[:root_dirty_field], with: "#{initial_title} "

          expect(page).to have_css('#infinite-tree-record-pane .record-toolbar.formchanged')

          within('#infinite-tree-record-pane .record-toolbar') do
            click_link 'Revert Changes'
          end

          aggregate_failures do
            within('#infinite-tree-record-pane') do
              expect(page).to have_css("#form_#{root_form_prefix}")
              expect(page).to have_field(config[:root_dirty_field], with: initial_title)
            end
            expect(page).to have_no_css('#infinite-tree-record-pane .record-toolbar.formchanged')
            expect(page.current_url).to match(%r{#{Regexp.escape(root_hash)}})
          end
        end
      end

      context 'for child' do
        it 'dismisses unsaved changes and reloads selected child record' do
          visit "#{edit_path}#{child_record_hash}"
          wait_for_infinite_tree_loaded

          initial_title = find_field(config[:child_revert_field]).value

          fill_in config[:child_revert_field], with: "#{initial_title} "

          expect(page).to have_css('#infinite-tree-record-pane .record-toolbar.formchanged')

          within('#infinite-tree-record-pane .record-toolbar') do
            click_link 'Revert Changes'
          end

          aggregate_failures do
            within('#infinite-tree-record-pane') do
              expect(page).to have_css("#form_#{child_form_prefix}")
              expect(page).to have_field(config[:child_revert_field], with: initial_title)
            end
            expect(page).to have_no_css('#infinite-tree-record-pane .record-toolbar.formchanged')
            expect(page.current_url).to match(%r{#{Regexp.escape(child_record_hash)}})
          end
        end
      end
    end

    describe 'modal actions' do
      it 'Save submits form, closes modal, and navigates to new record' do
        visit "#{edit_path}#{child_record_hash}"
        wait_for_infinite_tree_loaded
        fill_in config[:child_save_field], with: config[:child_save_value]
        wait_for_infinite_tree_record_pane_dirty
        within('#infinite-tree-container') { click_link root_record.title }

        within('#saveYourChangesModal') { click_on 'Save Changes' }
        wait_for_infinite_tree_current_node(root_record.uri)

        aggregate_failures do
          expect(page).not_to have_css('#saveYourChangesModal', visible: true)
          expect(page.current_url).to match(%r{#{root_hash}})
          within('#infinite-tree-record-pane') { expect(page).to have_css('h2', text: root_record.title) }
        end
      end

      it 'Dismiss discards changes, closes modal, and navigates to new record' do
        visit "#{edit_path}#{child_record_hash}"
        wait_for_infinite_tree_loaded
        fill_in config[:child_dirty_field], with: 'unsaved change'
        wait_for_infinite_tree_record_pane_dirty
        within('#infinite-tree-container') { click_link root_record.title }

        within('#saveYourChangesModal') { click_on 'Dismiss Changes' }
        wait_for_infinite_tree_current_node(root_record.uri)

        aggregate_failures do
          expect(page).not_to have_css('#saveYourChangesModal', visible: true)
          expect(page.current_url).to match(%r{#{root_hash}})
          within('#infinite-tree-record-pane') { expect(page).to have_css('h2', text: root_record.title) }
        end
      end

      it 'Cancel closes modal and stays on current record' do
        visit "#{edit_path}#{child_record_hash}"
        wait_for_infinite_tree_loaded
        fill_in config[:child_dirty_field], with: 'unsaved change'
        wait_for_infinite_tree_record_pane_dirty
        within('#infinite-tree-container') { click_link root_record.title }

        within('#saveYourChangesModal') { click_on 'Cancel' }

        aggregate_failures do
          expect(page).not_to have_css('#saveYourChangesModal', visible: true)
          expect(page.current_url).to match(%r{#{child_record_hash}})
          within('#infinite-tree-record-pane') { expect(page).to have_css('h2', text: child_record.title) }
        end
      end

      it 'Save with validation errors closes modal and stays on the invalid form' do
        visit "#{edit_path}#{root_hash}"
        wait_for_infinite_tree_loaded

        click_infinite_tree_toolbar_add_child
        wait_for_infinite_tree_pane_ready

        within('#infinite-tree-container') { click_link child_record.title }

        expect(page).to have_css('#saveYourChangesModal', visible: true)

        within('#saveYourChangesModal') { click_on 'Save Changes' }
        wait_for_infinite_tree_pane_ready

        aggregate_failures do
          expect(page).not_to have_css('#saveYourChangesModal', visible: true)
          expect(page.current_url).to match(/#new/)
          within('#infinite-tree-record-pane') do
            expect(page).to have_css('.error')
          end
          within('#infinite-tree-container') do
            expect(page).to have_css('li.js-itree-synthetic-new')
          end
        end

        within('#infinite-tree-container') { click_link child_record.title }
        expect(page).to have_css('#saveYourChangesModal', visible: true)
        within('#saveYourChangesModal') { click_on 'Cancel' }
      end
    end
  end

  describe 'after successful save' do
    it 'form has no unsaved changes; navigation proceeds without modal' do
      visit "#{edit_path}#{child_record_hash}"
      wait_for_infinite_tree_loaded

      updated_title = "Updated Title #{now}"
      fill_in config[:child_post_save_field], with: updated_title
      within('#infinite-tree-container') { click_link root_record.title }

      aggregate_failures do
        expect(page).to have_css('#saveYourChangesModal', visible: true)
        within('#saveYourChangesModal') { click_on 'Cancel' }

        find('button', text: child_save_label, match: :first).click
        expect(page).to have_text(updated_title)

        within('#infinite-tree-container') { click_link root_record.title }
        expect(page).not_to have_css('#saveYourChangesModal', visible: true)
        within('#infinite-tree-record-pane') { expect(page).to have_css('h2', text: root_record.title) }
      end
    end

    it 'refreshes the root row in the tree with the saved root data' do
      visit "#{edit_path}#{root_hash}"
      wait_for_infinite_tree_loaded

      updated_title = "Updated Root #{now}"
      fill_in config[:root_dirty_field], with: updated_title

      wait_for_infinite_tree_record_pane_submit do
        find('button', text: I18n.t("#{config[:root_type]}._frontend.action.save"), match: :first).click
      end

      root_title = find('#infinite-tree-container li.node.root > .node-row .record-title')

      aggregate_failures do
        expect(root_title).to have_text(updated_title)
        expect(root_title[:href]).to end_with(root_hash)
      end
    end
  end

  describe 'discarding changes on the way to a node that is not loaded yet' do
    it 'dispatches a single tree navigation' do
      nested_child_record
      target_hash = nested_child_record_hash

      visit "#{edit_path}#{child_record_hash}"
      wait_for_infinite_tree_loaded
      install_tree_event_capture('infiniteTreeRouter:setCurrentNode')

      fill_in config[:child_dirty_field], with: 'unsaved change'
      wait_for_infinite_tree_record_pane_dirty

      navigate_tree_hash(target_hash)
      expect(page).to have_css('#saveYourChangesModal', visible: true)

      within('#saveYourChangesModal') { click_on 'Dismiss Changes' }

      expect(page).to have_css(
        "#infinite-tree-container li.node.current[data-uri='#{nested_child_record.uri}']"
      )

      aggregate_failures do
        expect(page.current_url).to match(/#{Regexp.escape(target_hash)}/)
        expect(tree_event_count('infiniteTreeRouter:setCurrentNode')).to eq(1)
      end
    end
  end

  # A slow pane load must not overwrite a newer one.  hold_fetches lets each
  # example choose which of two overlapping loads finishes last.
  describe 'when a newer pane load starts before an earlier one finishes' do
    let(:root_load_url) { "#{edit_path}?inline=true" }
    let(:child_load_url) { "/#{child_type}s/#{child_record.id}/edit?inline=true" }
    let(:pane) { '#infinite-tree-record-pane' }

    before do
      visit "#{edit_path}#{child_record_hash}"
      wait_for_ajax
      wait_for_infinite_tree_pane_ready
    end

    it 'keeps the newer record when the earlier response arrives last' do
      hold_fetches(root_load_url)

      within('#infinite-tree-container') { click_link root_record.title }
      wait_for_held_fetch(root_load_url)

      within('#infinite-tree-container') { click_link child_record.title }
      expect(page).to have_css(infinite_tree_current_node_selector(child_record))
      wait_for_infinite_tree_pane_ready

      release_held_fetch(root_load_url)

      aggregate_failures do
        expect(page).to have_css(infinite_tree_current_node_selector(child_record))
        expect(page.current_url).to match(/#{Regexp.escape(child_record_hash)}/)
        expect(page).to have_no_css("#{pane}.blocked")
        within(pane) do
          expect(page).to have_css('h2', text: child_record.title)
          expect(page).to have_css("#form_#{child_type}")
          expect(page).to have_no_css('h2', text: root_record.title)
        end
      end
    end

    it 'keeps the pane blocked until the latest load finishes' do
      hold_fetches(root_load_url, child_load_url)

      within('#infinite-tree-container') { click_link root_record.title }
      wait_for_held_fetch(root_load_url)

      within('#infinite-tree-container') { click_link child_record.title }
      wait_for_held_fetch(child_load_url)

      release_held_fetch(root_load_url)

      aggregate_failures do
        expect(page).to have_css("#{pane}.blocked")
        within(pane) { expect(page).to have_no_css('h2', text: root_record.title) }
      end

      release_held_fetch(child_load_url)

      aggregate_failures do
        expect(page).to have_no_css("#{pane}.blocked")
        expect(page).to have_css(infinite_tree_current_node_selector(child_record))
        within(pane) { expect(page).to have_css('h2', text: child_record.title) }
      end
    end

    it 'keeps an Add Child form when the earlier record response arrives last' do
      hold_fetches(root_load_url)

      within('#infinite-tree-container') { click_link root_record.title }
      wait_for_held_fetch(root_load_url)
      expect(page).to have_css(infinite_tree_current_node_selector(root_record))

      click_infinite_tree_toolbar_add_child
      expect(page).to have_css("#{pane} form[action$='/#{child_type}s']")

      release_held_fetch(root_load_url)

      aggregate_failures do
        expect(page).to have_no_css("#{pane}.blocked")
        expect(page).to have_css("#{pane} form[action$='/#{child_type}s']")
        expect(page).to have_css("#infinite-tree-container li##{child_type}_new.js-itree-synthetic-new")
        within(pane) { expect(page).to have_no_css('h2', text: root_record.title) }
      end
    end

    it 'keeps an Add Sibling form when the earlier record response arrives last' do
      hold_fetches(child_load_url)

      within('#infinite-tree-container') { click_link root_record.title }
      wait_for_infinite_tree_pane_ready

      within('#infinite-tree-container') { click_link child_record.title }
      wait_for_held_fetch(child_load_url)
      expect(page).to have_css(infinite_tree_current_node_selector(child_record))

      find('.js-itree-toolbar-add-sibling').click
      wait_for_infinite_tree_pane_ready
      expect(page).to have_css("#{pane} form[action$='/#{child_type}s']")

      release_held_fetch(child_load_url)

      aggregate_failures do
        expect(page).to have_no_css("#{pane}.blocked")
        expect(page).to have_css("#{pane} form[action$='/#{child_type}s']")
        expect(page).to have_css("#infinite-tree-container li##{child_type}_new.js-itree-synthetic-new")
        within(pane) { expect(page).to have_no_css('h2', text: child_record.title) }
      end
    end
  end

  # Save uses fetch POST; tree navigation uses GET ?inline=true, so hold the save,
  # navigate on a clean form, then release the save.
  describe 'when navigation starts while a save request is still in flight' do
    let(:child_save_url) { "/#{child_type}s/#{child_record.id}" }
    let(:pane) { '#infinite-tree-record-pane' }

    before do
      visit "#{edit_path}#{child_record_hash}"
      wait_for_infinite_tree_pane_ready
    end

    it 'keeps the navigated record when the save response arrives last' do
      hold_fetches(child_save_url, methods: %w[POST PUT PATCH])

      find('button', text: child_save_label, match: :first).click
      wait_for_held_fetch(child_save_url)

      within('#infinite-tree-container') { click_link root_record.title }
      expect(page).to have_css(infinite_tree_current_node_selector(root_record))
      wait_for_infinite_tree_pane_ready

      release_held_fetch(child_save_url)

      aggregate_failures do
        expect(page).to have_css(infinite_tree_current_node_selector(root_record))
        expect(page.current_url).to match(/#{Regexp.escape(root_hash)}/)
        expect(page).to have_no_css("#{pane}.blocked")
        within(pane) do
          expect(page).to have_css('h2', text: root_record.title)
          expect(page).to have_css("#form_#{root_type}")
          expect(page).to have_no_css("#form_#{child_type}")
        end
      end
    end
  end
end
