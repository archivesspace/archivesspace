# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Tree UI', js: true do
  let(:admin_user) { BackendClientMethods::ASpaceUser.new('admin', 'admin') }

  before(:all) do
    @repository = create(:repo, repo_code: "trees_test_#{Time.now.to_i}")

    run_all_indexers
  end

  before (:each) do
    login_user(admin_user)
    select_repository(@repository)

    @now = Time.now.to_i

    @resource = create(:resource)
    @archival_object_1 = create(:archival_object, title: "Archival Object Title 1 #{@now}", resource: { ref: @resource.uri })
    @archival_object_2 = create(:archival_object, title: "Archival Object Title 2 #{@now}", resource: { ref: @resource.uri })
    @archival_object_3 = create(:archival_object, title: "Archival Object Title 3 #{@now}", resource: { ref: @resource.uri })
    @archival_object_4 = create(:archival_object, title: "Archival Object Title 4 #{@now}", resource: { ref: @resource.uri })
    @archival_object_4.set_suppressed(true)

    run_index_round

    visit "resources/#{@resource.id}/edit"
    expect(page).to have_text @resource.title
  end

  xit 'can add a sibling' do
    element = all('.root-row')
    expect(element.length).to eq(1)

    elements = all('.largetree-node')
    expect(elements.length).to eq(4)

    click_link "Archival Object Title 3 #{@now}"
    click_on 'Add Sibling'

    expect(page).to have_text 'Archival Object'
    expect(page).to have_text 'Basic Information'
    expect(page).to have_css("#archival_object_title_")
    expect(page).to have_css('#archival_object_level_')

    fill_in 'Title', with: "Sibling #{@now}"
    select 'Item', from: 'Level of Description'

    # Click on save
    element = find('button', text: 'Save', match: :first)
    element.click

    expect(page).to have_text "Archival Object Sibling #{@now} on Resource #{@resource.title} created"

    elements = all('.largetree-node')
    expect(elements.length).to eq(5)

    visit "resources/#{@resource.id}/edit"

    element = all('.root-row')
    expect(element.length).to eq(1)

    elements = all('.largetree-node')
    expect(elements.length).to eq(5)
  end

  xit 'can retain location hash when sidebar items are clicked' do
    click_link "Archival Object Title 1 #{@now}"

    url_hash = current_url.split('#').last
    expect(url_hash).to eq("tree::archival_object_#{@archival_object_1.id}")

    find('.sidebar-entry-notes a').click

    url_hash = current_url.split('#').last
    expect(url_hash).to eq("tree::archival_object_#{@archival_object_1.id}")
  end

  it 'shows the suppressed tag only for suppressed records' do
    elements = all('#tree-container > .table.root > .table-row-group > div > .title > a.record-title > span.label.label-info')
    expect(elements.length).to eq(1)

    element = find("div[title=\"#{@archival_object_4.title}\"]")
    expect(element).to have_text 'Suppressed'
  end
end
