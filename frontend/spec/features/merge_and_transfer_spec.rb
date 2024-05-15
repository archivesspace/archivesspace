# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Merging and transfering resources', js: true do
  let(:admin) { BackendClientMethods::ASpaceUser.new('admin', 'admin') }

  before(:all) do
    now = Time.now.to_i
    @repository_source = create(:repo, repo_code: "transfer_test_source_#{now}")
    @repository_target = create(:repo, repo_code: "transfer_test_target_#{now}")

    set_repo @repository_source
  end

  before(:each) do
    login_user(admin)
  end

  it 'can transfer a resource to another repository and open it for editing' do
    select_repository(@repository_source)
    set_repo @repository_source
    resource = create(:resource)
    run_index_round

    visit "resources/#{resource.id}/edit"
    find('#transfer-dropdown button').click
    select @repository_target.repo_code, from: 'transfer_ref_'

    within '.dropdown-menu.transfer-form' do
      click_on 'Transfer'
    end

    within '#confirmChangesModal' do
      click_on 'Transfer'
    end

    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Transfer Successful. Records may take a moment to appear in the target repository while re-indexing takes place.'

    run_all_indexers

    visit '/'
    select_repository(@repository_target)
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "The Repository #{@repository_target.repo_code} is now active"

    click_on 'Browse'
    click_on 'Resources'

    expect(page).to have_css 'tr', text: resource.title
  end

  it 'can merge a resource into a resource' do
    now = Time.now.to_i

    select_repository(@repository_source)

    set_repo @repository_source
    resource_source = create(:resource)
    resource_target = create(:resource)

    archival_objects_source = (0...10).map do |index|
      create(:archival_object, title: "Archival Object Source Title #{index} #{now}", resource: { 'ref' => resource_source.uri })
    end

    archival_objects_target = (0...10).map do |index|
      create(:archival_object, title: "Archival Object Target Title #{index} #{now}", resource: { 'ref' => resource_target.uri })
    end

    run_index_round

    visit "resources/#{resource_target.id}/edit"

    find('#merge-dropdown button').click
    fill_in 'token-input-merge_ref_', with: resource_source.title
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    within '.dropdown-menu.merge-form' do
      click_on 'Merge'
    end

    within '#confirmChangesModal' do
      click_on 'Merge'
    end

    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Resource(s) Merged'

    elements = all('#tree-container .table-row.largetree-node.indent-level-1')
    expect(elements.length).to eq 20

    ids = archival_objects_source.map { |entry| "archival_object_#{entry.id}" }
    ids += archival_objects_target.map { |entry| "archival_object_#{entry.id}" }
    ids_from_dom = elements.map { |element| element[:id] }
    expect(ids.sort == ids_from_dom.sort).to eq true
  end

  it 'can merge an archival objects into a resource' do
    now = Time.now.to_i

    select_repository(@repository_source)

    resource = create(:resource, title: "Resource Title #{now}")
    archival_object = create(:archival_object, title: "Archival Object Title #{now}", resource: { 'ref' => resource.uri })
    run_index_round

    visit "resources/#{resource.id}/edit#tree::archival_object_#{archival_object.id}"

    click_on 'Transfer'

    fill_in 'token-input-transfer_ref_', with: resource.title
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    within '.dropdown-menu.tree-transfer-form' do
      click_on 'Transfer'
    end

    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "Successfully transferred Archival Object #{archival_object.title} to Resource #{resource.title}"

    expect(page).to have_css "#archival_object_#{archival_object.id}"
  end

  it 'can merge a digital object into a digital object' do
    now = Time.now.to_i

    set_repo @repository_source
    digital_object_source = create(:digital_object, title: "Digital Object Source Title #{now}")
    digital_object_target = create(:digital_object, title: "Digital Object Target Title #{now}")

    select_repository(@repository_source)

    run_index_round

    visit "digital_objects/#{digital_object_source.id}/"

    click_on 'Merge'
    fill_in 'token-input-merge_ref_', with: digital_object_target.title
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    within '.dropdown-menu.merge-form' do
      click_on 'Merge'
    end

    within '#confirmChangesModal' do
      click_on 'Merge'
    end

    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Digital object(s) Merged'
  end
end
