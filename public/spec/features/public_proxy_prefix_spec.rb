# frozen_string_literal: true

require 'uri'
require 'spec_helper'
require 'rails_helper'

# These examples only run when ASPACE_TEST_PUBLIC_PROXY_PREFIX=true (see spec_helper.rb).
# Default proxy path matches public:devserver:prefix (APPCONFIG_PUBLIC_PROXY_URL …/public).
# Run separately from the main suite — the env var changes where routes are mounted:
#
#   ASPACE_TEST_PUBLIC_PROXY_PREFIX=true ./build/run public:test \
#     -Dpattern="features/public_proxy_prefix_spec.rb"
describe 'Public UI with public_proxy_prefix', js: true, if: ENV['ASPACE_TEST_PUBLIC_PROXY_PREFIX'] == 'true' do
  include PublicProxyPrefixFeatureHelpers

  let(:prefix) { pui_proxy_path_prefix }

  it 'mounts the welcome page under the proxy path' do
    visit_prefixed('/')
    page.has_text? "Welcome to ArchivesSpace"
  end

  it 'renders the main search form action with the proxy prefix' do
    visit_prefixed('/')
    action = find('#advanced_search', visible: :all)[:action]
    expect(action).to include("#{prefix}/search")
  end

  it 'renders navbar links with the proxy prefix' do
    visit_prefixed('/')
    href = find_link('Repositories')[:href]
    expect(href).to include("#{prefix}/repositories")
  end

  it 'renders collection overview page actions, tabs, sidebar search, and breadcrumbs with the proxy prefix' do
    visit_prefixed('/')
    click_link 'Collections'
    fill_in 'Search within results', with: 'Published Resource'
    click_button 'Search'
    first("a[class='record-title']", text: 'Published Resource').click

    aggregate_failures do
      expect(find('#cite_sub', visible: :all)[:action]).to include("#{prefix}/cite")

      request_action = find('#request_sub', visible: :all)[:action]
      expect(request_action).to include("#{prefix}/repositories/", '/request')

      print_action = find('#print_form', visible: :all)[:action]
      expect(print_action).to include("#{prefix}/repositories/", '/pdf')

      crumb_href = first('.breadcrumb a')[:href]
      expect(URI.parse(crumb_href).path).to start_with("#{prefix}/")

      co_href = find('a.nav-link[href*="collection_organization"]')[:href]
      expect(URI.parse(co_href).path).to start_with("#{prefix}/")

      search_action = find('#sidebar .search form', visible: :all)[:action]
      expect(search_action).to include("#{prefix}/repositories/", '/search')

      expect(find('#request_form', visible: :all)[:action]).to include("#{prefix}/fill_request")
    end
  end

  it 'renders creator agent links in upper record details with the proxy prefix' do
    visit_prefixed('/')
    click_link 'Collections'
    fill_in 'Search within results', with: 'Resource with Agents'
    click_button 'Search'
    click_link 'Resource with Agents'

    within('.upper-record-details .present_list.agents_list', match: :first) do
      expect(page).to have_css('a[href]')
      expect(first('a')[:href]).to include("#{prefix}/agents/")
    end
  end

  it 'renders topical subject links in the Subjects accordion with the proxy prefix' do
    visit_prefixed('/')
    click_link 'Collections'
    fill_in 'Search within results', with: 'Resource with Subject'
    click_button 'Search'
    click_link 'Resource with Subject'

    expect(page).to have_css('#subj_list .present_list.subjects_list')
    within('#subj_list .present_list.subjects_list') do
      expect(page).to have_css('a[href]')
      subject_href = first('a')[:href]
      expect(subject_href).to include("#{prefix}/subjects/")
    end
  end
end
