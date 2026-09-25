# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree toolbar action matrix', js: true do
  before(:all) do
    now = Time.now.to_i
    @repo = create(:repo, repo_code: "itree_toolbar_matrix_#{now}")
    set_repo(@repo)
  end

  before do
    login_admin
    select_repository(@repo)
  end

  def expect_itree_toolbar_to_include(*labels)
    labels.each do |label|
      expect(page).to have_css('#infinite-tree-toolbar', text: label)
    end
  end

  def expect_itree_toolbar_to_exclude(*labels)
    labels.each do |label|
      expect(page).to have_no_css('#infinite-tree-toolbar', text: label)
    end
  end

  it 'shows resource-root actions' do
    resource = create(:resource, title: "Matrix Resource #{Time.now.to_i}")
    create(:archival_object, title: 'Matrix AO', resource: { ref: resource.uri })
    run_indexer

    visit "resources/#{resource.id}/edit"
    wait_for_ajax

    expect(page).to have_css('#infinite-tree-toolbar .js-itree-toolbar-reorder-toggle')
    expect_itree_toolbar_to_include(
      I18n.t('actions.expand_tree_mode_on'),
      I18n.t('actions.collapse_tree'),
      I18n.t('resource._frontend.action.add_child'),
      I18n.t('resource._frontend.action.load_bulk'),
      I18n.t('actions.rapid_data_entry')
    )
    expect(page).to have_css('#load_via_spreadsheet_help_icon')
    expect(page).to have_css(
      '.js-itree-toolbar-add-sibling',
      visible: :hidden,
      text: I18n.t('archival_object._frontend.action.add_sibling')
    )
    expect(page).to have_css(
      '.js-itree-toolbar-add-duplicate',
      visible: :hidden,
      text: I18n.t('archival_object._frontend.action.add_duplicate')
    )
  end

  it 'shows archival object actions when an archival object node is selected' do
    now = Time.now.to_i
    resource = create(:resource, title: "Matrix Resource AO #{now}")
    archival_object = create(
      :archival_object,
      title: "Matrix AO #{now}",
      resource: { ref: resource.uri }
    )
    run_indexer

    visit "resources/#{resource.id}/edit"
    wait_for_ajax
    select_tree_row(archival_object)

    expect_itree_toolbar_to_include(
      I18n.t('resource._frontend.action.add_child'),
      I18n.t('archival_object._frontend.action.add_sibling'),
      I18n.t('archival_object._frontend.action.add_duplicate'),
      I18n.t('resource._frontend.action.load_bulk'),
      I18n.t('actions.rapid_data_entry'),
      I18n.t('actions.expand_tree_mode_on'),
      I18n.t('actions.collapse_tree')
    )
    expect(page).to have_css('#load_via_spreadsheet_help_icon')
  end

  it 'shows digital object root and component actions' do
    now = Time.now.to_i
    digital_object = create(:digital_object, title: "Matrix DO #{now}")
    component = create(
      :digital_object_component,
      title: "Matrix DOC #{now}",
      digital_object: { ref: digital_object.uri }
    )
    run_indexer

    visit "digital_objects/#{digital_object.id}/edit"
    wait_for_ajax

    expect(page).to have_css('#infinite-tree-toolbar .js-itree-toolbar-reorder-toggle')
    expect_itree_toolbar_to_include(
      I18n.t('digital_object._frontend.action.add_child'),
      I18n.t('actions.rapid_data_entry'),
      I18n.t('actions.expand_tree_mode_on'),
      I18n.t('actions.collapse_tree')
    )
    expect(page).to have_no_css('.js-itree-toolbar-load-bulk')
    expect(page).to have_no_css('#load_via_spreadsheet_help_icon')
    expect(page).to have_no_css('.js-itree-toolbar-add-duplicate')
    expect(page).to have_css(
      '.js-itree-toolbar-add-sibling',
      visible: :hidden,
      text: I18n.t('digital_object_component._frontend.action.add_sibling')
    )

    select_tree_row(component)
    expect_itree_toolbar_to_include(
      I18n.t('digital_object._frontend.action.add_child'),
      I18n.t('digital_object_component._frontend.action.add_sibling'),
      I18n.t('actions.rapid_data_entry'),
      I18n.t('actions.expand_tree_mode_on'),
      I18n.t('actions.collapse_tree')
    )
    expect(page).to have_no_css('.js-itree-toolbar-load-bulk')
    expect(page).to have_no_css('.js-itree-toolbar-add-duplicate')
  end

  it 'shows classification root and term actions' do
    now = Time.now.to_i
    classification = create(:classification, title: "Matrix Classification #{now}")
    term = create(
      :classification_term,
      title: "Matrix Term #{now}",
      classification: { ref: classification.uri }
    )
    run_indexer

    visit "classifications/#{classification.id}/edit"
    wait_for_ajax

    expect(page).to have_css('#infinite-tree-toolbar .js-itree-toolbar-reorder-toggle')
    expect_itree_toolbar_to_include(
      I18n.t('classification._frontend.action.add_child'),
      I18n.t('actions.expand_tree_mode_on'),
      I18n.t('actions.collapse_tree')
    )
    expect(page).to have_no_css('.js-itree-toolbar-load-bulk')
    expect(page).to have_no_css('#load_via_spreadsheet_help_icon')
    expect(page).to have_no_css('.js-itree-toolbar-rde')
    expect(page).to have_no_css('.js-itree-toolbar-add-duplicate')
    expect(page).to have_css(
      '.js-itree-toolbar-add-sibling',
      visible: :hidden,
      text: I18n.t('classification_term._frontend.action.add_sibling')
    )

    select_tree_row(term)
    expect_itree_toolbar_to_include(
      I18n.t('classification._frontend.action.add_child'),
      I18n.t('classification_term._frontend.action.add_sibling'),
      I18n.t('actions.expand_tree_mode_on'),
      I18n.t('actions.collapse_tree')
    )
    expect(page).to have_no_css('.js-itree-toolbar-load-bulk')
    expect(page).to have_no_css('.js-itree-toolbar-rde')
    expect(page).to have_no_css('.js-itree-toolbar-add-duplicate')
  end
end
