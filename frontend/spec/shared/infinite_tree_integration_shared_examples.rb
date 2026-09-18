# frozen_string_literal: true

# Shared setup and examples for Infinite Tree integration specs.
# Examples are parameterized by view (show vs edit) and scenario.

RSpec.shared_context 'infinite tree integration setup' do
  let(:now) { Time.now.to_i }
  let(:repo) { create(:repo, repo_code: "infinite_tree_integration_#{now}") }
  let(:resource) { create(:resource, title: "Resource #{now}") }
  let(:ao) { create(:archival_object, resource: { 'ref' => resource.uri }, title: "Archival Object #{now}") }

  # Record-type-agnostic aliases (Resources mapping today; swap via config later).
  let(:root_record) { resource }
  let(:child_record) { ao }
  let(:child_record_hash) { "#tree::archival_object_#{child_record.id}" }
  let(:nested_child_record) do
    create(
      :archival_object,
      resource: { 'ref' => resource.uri },
      parent: { 'ref' => child_record.uri },
      title: "Nested Child Record #{now}"
    )
  end
  let(:nested_child_record_hash) { "#tree::archival_object_#{nested_child_record.id}" }
  let(:root_form_prefix) { 'resource' }
  let(:child_form_prefix) { 'archival_object' }

  before do
    set_repo(repo)
    login_admin
    select_repository(repo)
    ao
  end
end

# path_let: symbol for let that returns the path (e.g. :show_path)
# view_type: :show (readonly pane) or :edit (edit form)
RSpec.shared_examples 'adds root hash and displays root on load' do |path_let, view_type|
  it "adds root hash and displays root (#{view_type})" do
    path = send(path_let)
    visit path
    wait_for_ajax

    aggregate_failures do
      expect(page.current_url).to match(%r{#{Regexp.escape(path)}#tree::resource_})
      expect(page).to have_css('#infinite-tree-container .root.current')
      expect(page).to have_css(
        '#infinite-tree-container .node.current',
        count: 1,
        visible: :all
      )
      within('#infinite-tree-record-pane') do
        expect(page).to have_css('h2', text: resource.title)
        case view_type
        when :show
          expect(page).to have_css('.readonly-context')
          expect(page).to have_field('uri', with: resource.uri)
        when :edit
          expect(page).to have_css('#form_resource')
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
    wait_for_ajax

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
    wait_for_ajax

    within('#infinite-tree-container') { click_link node.title }
    wait_for_ajax

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

RSpec.shared_examples 'infinite tree integration edit parity' do |config|
  include_context 'infinite tree integration hierarchy setup', config.merge(run_indexer: true)

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
        wait_for_ajax

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
        wait_for_ajax

        page.execute_script("window.location.hash = 'tree::#{child_type}_#{child_record.id}'")
        wait_for_ajax

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
      wait_for_ajax
      fill_in config[:child_dirty_field], with: 'unsaved change'
      wait_for_ajax

      page.execute_script("window.location.hash = 'tree::#{root_type}_#{root_record.id}'")
      wait_for_ajax

      aggregate_failures do
        expect(page).to have_css('#saveYourChangesModal', visible: true)
        expect(page.current_url).to match(%r{#{child_record_hash}})

        within('#saveYourChangesModal') { click_on 'Cancel' }
        expect(page).not_to have_css('#saveYourChangesModal', visible: true)
      end
    end

    it 'guard shows modal on tree title click' do
      visit "#{edit_path}#{child_record_hash}"
      wait_for_ajax
      fill_in config[:child_dirty_field], with: 'unsaved change'
      wait_for_ajax

      within('#infinite-tree-container') { click_link root_record.title }
      wait_for_ajax

      expect(page).to have_css('#saveYourChangesModal', visible: true)
      within('#infinite-tree-record-pane') { expect(page).to have_css('h2', text: child_record.title) }
    end

    describe 'Revert Changes' do
      context 'for root' do
        it 'dismisses unsaved changes and reloads selected root record' do
          visit "#{edit_path}#{root_hash}"
          wait_for_ajax

          initial_title = find_field(config[:root_dirty_field]).value

          fill_in config[:root_dirty_field], with: "#{initial_title} "
          wait_for_ajax

          expect(page).to have_css('#infinite-tree-record-pane .record-toolbar.formchanged')

          within('#infinite-tree-record-pane .record-toolbar') do
            click_link 'Revert Changes'
          end
          wait_for_ajax

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
          wait_for_ajax

          initial_title = find_field(config[:child_revert_field]).value

          fill_in config[:child_revert_field], with: "#{initial_title} "
          wait_for_ajax

          expect(page).to have_css('#infinite-tree-record-pane .record-toolbar.formchanged')

          within('#infinite-tree-record-pane .record-toolbar') do
            click_link 'Revert Changes'
          end
          wait_for_ajax

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
        wait_for_ajax
        fill_in config[:child_save_field], with: config[:child_save_value]
        wait_for_ajax
        within('#infinite-tree-container') { click_link root_record.title }
        wait_for_ajax

        within('#saveYourChangesModal') { click_on 'Save Changes' }
        wait_for_ajax

        aggregate_failures do
          expect(page).not_to have_css('#saveYourChangesModal', visible: true)
          expect(page.current_url).to match(%r{#{root_hash}})
          within('#infinite-tree-record-pane') { expect(page).to have_css('h2', text: root_record.title) }
        end
      end

      it 'Dismiss discards changes, closes modal, and navigates to new record' do
        visit "#{edit_path}#{child_record_hash}"
        wait_for_ajax
        fill_in config[:child_dirty_field], with: 'unsaved change'
        wait_for_ajax
        within('#infinite-tree-container') { click_link root_record.title }
        wait_for_ajax

        within('#saveYourChangesModal') { click_on 'Dismiss Changes' }
        wait_for_ajax

        aggregate_failures do
          expect(page).not_to have_css('#saveYourChangesModal', visible: true)
          expect(page.current_url).to match(%r{#{root_hash}})
          within('#infinite-tree-record-pane') { expect(page).to have_css('h2', text: root_record.title) }
        end
      end

      it 'Cancel closes modal and stays on current record' do
        visit "#{edit_path}#{child_record_hash}"
        wait_for_ajax
        fill_in config[:child_dirty_field], with: 'unsaved change'
        wait_for_ajax
        within('#infinite-tree-container') { click_link root_record.title }
        wait_for_ajax

        within('#saveYourChangesModal') { click_on 'Cancel' }
        wait_for_ajax

        aggregate_failures do
          expect(page).not_to have_css('#saveYourChangesModal', visible: true)
          expect(page.current_url).to match(%r{#{child_record_hash}})
          within('#infinite-tree-record-pane') { expect(page).to have_css('h2', text: child_record.title) }
        end
      end

      it 'Save with validation errors closes modal and stays on the invalid form' do
        visit "#{edit_path}#{root_hash}"
        wait_for_ajax
        wait_for_infinite_tree_pane_ready

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
      wait_for_ajax

      updated_title = "Updated Title #{now}"
      fill_in config[:child_post_save_field], with: updated_title
      within('#infinite-tree-container') { click_link root_record.title }
      wait_for_ajax

      aggregate_failures do
        expect(page).to have_css('#saveYourChangesModal', visible: true)
        within('#saveYourChangesModal') { click_on 'Cancel' }

        find('button', text: child_save_label, match: :first).click
        wait_for_ajax
        expect(page).to have_text(updated_title)

        within('#infinite-tree-container') { click_link root_record.title }
        wait_for_ajax
        expect(page).not_to have_css('#saveYourChangesModal', visible: true)
        within('#infinite-tree-record-pane') { expect(page).to have_css('h2', text: root_record.title) }
      end
    end
  end

  describe 'discarding changes on the way to a node that is not loaded yet' do
    it 'dispatches a single tree navigation' do
      nested_child_record
      run_indexer
      target_hash = nested_child_record_hash

      visit "#{edit_path}#{child_record_hash}"
      wait_for_ajax
      install_tree_event_capture('infiniteTreeRouter:setCurrentNode')

      fill_in config[:child_dirty_field], with: 'unsaved change'
      wait_for_ajax

      navigate_tree_hash(target_hash)
      expect(page).to have_css('#saveYourChangesModal', visible: true)

      within('#saveYourChangesModal') { click_on 'Dismiss Changes' }
      wait_for_ajax

      expect(page).to have_css(
        "#infinite-tree-container li.node.current[data-uri='#{nested_child_record.uri}']"
      )

      aggregate_failures do
        expect(page.current_url).to match(/#{Regexp.escape(target_hash)}/)
        expect(tree_event_count('infiniteTreeRouter:setCurrentNode')).to eq(1)
      end
    end
  end
end
