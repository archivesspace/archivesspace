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

  def expect_infinite_tree_toolbar_to_include(*labels)
    labels.each do |label|
      expect(page).to have_css('#infinite-tree-toolbar', text: label)
    end
  end

  it 'shows digital object root and component actions' do
    now = Time.now.to_i
    digital_object = create(:digital_object, title: "Matrix DO #{now}")
    component = create(:digital_object_component, title: "Matrix DOC #{now}", digital_object: { ref: digital_object.uri })
    run_indexer

    visit "digital_objects/#{digital_object.id}/edit"

    wait_for_infinite_tree_pane_ready

    expect(page).to have_css('#infinite-tree-toolbar .js-itree-toolbar-reorder-toggle')
    expect_infinite_tree_toolbar_to_include(
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
    expect_infinite_tree_toolbar_to_include(
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
    term = create(:classification_term, title: "Matrix Term #{now}", classification: { ref: classification.uri })
    run_indexer

    visit "classifications/#{classification.id}/edit"
    wait_for_infinite_tree_pane_ready

    expect(page).to have_css('#infinite-tree-toolbar .js-itree-toolbar-reorder-toggle')
    expect_infinite_tree_toolbar_to_include(
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
    expect_infinite_tree_toolbar_to_include(
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
