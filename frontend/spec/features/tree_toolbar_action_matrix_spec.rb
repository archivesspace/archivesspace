# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Tree toolbar action matrix', js: true do
  before(:all) do
    now = Time.now.to_i
    @repo = create(:repo, repo_code: "toolbar_matrix_#{now}")
    set_repo(@repo)
  end

  before(:each) do
    login_admin
    select_repository(@repo)
  end

  def expect_toolbar_to_include(*labels)
    labels.each do |label|
      expect(page).to have_css('#tree-toolbar', text: label)
    end
  end

  def expect_toolbar_to_exclude(*labels)
    labels.each do |label|
      expect(page).to have_no_css('#tree-toolbar', text: label)
    end
  end

  it 'shows resource-root actions' do
    resource = create(:resource, title: "Matrix Resource #{Time.now.to_i}")
    create(:archival_object, title: 'Matrix AO', resource: { ref: resource.uri })
    run_indexer

    visit "resources/#{resource.id}/edit"
    wait_for_ajax

    skip_if_infinite_tree_toolbar_active

    expect(page).to have_css('#tree-toolbar .drag-toggle')
    expect_toolbar_to_include('Auto-Expand All', 'Collapse Tree', 'Add Child', 'Load via Spreadsheet', 'Rapid Data Entry')
    expect_toolbar_to_exclude('Add Sibling', 'Add Duplicate')
  end

  it 'shows archival object actions when an archival object node is selected' do
    now = Time.now.to_i
    resource = create(:resource, title: "Matrix Resource AO #{now}")
    archival_object = create(:archival_object, title: "Matrix AO #{now}", resource: { ref: resource.uri })
    run_indexer

    visit "resources/#{resource.id}/edit"
    wait_for_ajax
    click_on archival_object.title

    skip_if_infinite_tree_toolbar_active

    expect_toolbar_to_include('Add Child', 'Add Sibling', 'Add Duplicate', 'Load via Spreadsheet', 'Rapid Data Entry', 'Auto-Expand All', 'Collapse Tree')
  end

  it 'shows digital object root and component actions' do
    now = Time.now.to_i
    digital_object = create(:digital_object, title: "Matrix DO #{now}")
    component = create(:digital_object_component, title: "Matrix DOC #{now}", digital_object: { ref: digital_object.uri })
    run_indexer

    visit "digital_objects/#{digital_object.id}/edit"
    wait_for_ajax

    expect(page).to have_css('#tree-toolbar .drag-toggle')
    expect_toolbar_to_include('Add Child', 'Rapid Data Entry')
    expect_toolbar_to_exclude('Load via Spreadsheet', 'Auto-Expand All', 'Collapse Tree', 'Add Sibling', 'Add Duplicate')

    click_on component.title
    expect_toolbar_to_include('Add Child', 'Add Sibling', 'Rapid Data Entry')
    expect_toolbar_to_exclude('Load via Spreadsheet', 'Add Duplicate')
  end

  it 'shows classification root and term actions' do
    now = Time.now.to_i
    classification = create(:classification, title: "Matrix Classification #{now}")
    term = create(:classification_term, title: "Matrix Term #{now}", classification: { ref: classification.uri })
    run_indexer

    visit "classifications/#{classification.id}/edit"
    wait_for_ajax

    expect(page).to have_css('#tree-toolbar .drag-toggle')
    expect_toolbar_to_include('Add Child')
    expect_toolbar_to_exclude('Load via Spreadsheet', 'Auto-Expand All', 'Collapse Tree', 'Add Sibling', 'Add Duplicate', 'Rapid Data Entry')

    click_on term.title
    expect_toolbar_to_include('Add Child', 'Add Sibling')
    expect_toolbar_to_exclude('Load via Spreadsheet', 'Add Duplicate', 'Rapid Data Entry')
  end
end
