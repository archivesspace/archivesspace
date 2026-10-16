# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree expand buttons', js: true do
  before(:all) do
    @now = Time.now.to_i
    @repo = create(:repo, repo_code: "itree_expand_button_test_#{@now}")
    set_repo(@repo)

    @resource = create(:resource, title: "Expand Button Resource #{@now}", publish: true)
    @parent = create(:archival_object,
      resource: { 'ref' => @resource.uri },
      title: "Parent AO #{@now}",
      publish: true
    )
    @child = create(:archival_object,
      resource: { 'ref' => @resource.uri },
      parent: { 'ref' => @parent.uri },
      title: "Child AO #{@now}",
      publish: true
    )

  end

  before(:each) do
    login_admin
    select_repository(@repo)
  end

  let(:edit_path) { "/resources/#{@resource.id}/edit" }
  let(:parent_node) { "#archival_object_#{@parent.id}" }
  let(:expand_button) { "#{parent_node} > .node-row .node-expand" }

  def expand_button_label
    find(expand_button).evaluate_script(<<~JS)
      Array.from(this.querySelectorAll('.node-expand-label'))
        .filter(el => getComputedStyle(el).display !== 'none')
        .map(el => el.textContent)
        .join('')
    JS
  end

  def node_title
    find("#{parent_node} > .node-row .record-title").text
  end

  context 'in English' do
    before(:each) do
      visit edit_path
      wait_for_ajax
    end

    it 'names the action the button will take' do
      expect(page).to have_css("#{parent_node}[aria-expanded='false']")
      expect(expand_button_label).to eq("Expand #{node_title}")

      find(expand_button).click
      expect(page).to have_css("#{parent_node}[aria-expanded='true']")
      expect(expand_button_label).to eq("Collapse #{node_title}")
    end

    it 'toggles with Return and Space from the keyboard' do
      find(expand_button).execute_script('this.focus()')

      page.active_element.send_keys(:enter)
      expect(page).to have_css("#{parent_node}[aria-expanded='true']")

      page.active_element.send_keys(:space)
      expect(page).to have_css("#{parent_node}[aria-expanded='false']")
    end
  end

  context 'in another locale' do
    before do
      set_admin_locale_preference(:fr)
      visit_in_locale(edit_path, :fr)
    end

    after { set_admin_locale_preference(:en) }

    it 'renders the labels in the active locale' do
      expect(expand_button_label)
        .to eq(I18n.t('actions.expand_node', title: node_title, locale: :fr))

      find(expand_button).click
      expect(page).to have_css("#{parent_node}[aria-expanded='true']")
      expect(expand_button_label)
        .to eq(I18n.t('actions.collapse_node', title: node_title, locale: :fr))
    end
  end
end
