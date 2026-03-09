# frozen_string_literal: true

# Shared setup and examples for Infinite Tree integration specs.
# Examples are parameterized by view (show vs edit) and scenario.

RSpec.shared_context 'infinite tree integration setup' do
  let(:now) { Time.now.to_i }
  let(:repo) { create(:repo, repo_code: "infinite_tree_integration_#{now}") }
  let(:resource) { create(:resource, title: "Resource #{now}") }
  let(:ao) { create(:archival_object, resource: { 'ref' => resource.uri }, title: "Archival Object #{now}") }

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
      expect(page).to have_css('#infinite-tree-container .root.selected')
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
