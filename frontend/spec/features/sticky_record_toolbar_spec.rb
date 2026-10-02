# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Sticky record toolbar', js: true do
  let(:now) { Time.now.to_i }
  let(:title) { "Sticky toolbar #{now}" }

  before(:all) do
    @repo = create(:repo, repo_code: "sticky_toolbar_#{Time.now.to_i}_#{SecureRandom.hex(2)}")
  end

  before(:each) do
    set_repo(@repo)
    login_admin_and_select_repository(@repo)
    page.current_window.resize_to(1200, 600)
  end

  after(:each) { page.current_window.resize_to(1400, 1000) }

  let(:accession) { create(:accession, title: title) }
  let(:resource) { create(:resource, title: title) }
  let(:archival_object) do
    create(:archival_object, title: title, resource: { ref: resource.uri })
  end
  let(:digital_object) { create(:digital_object, title: title) }
  let(:digital_object_component) do
    create(:digital_object_component, title: title, digital_object: { ref: digital_object.uri })
  end

  def toolbar_rect(selector = '.sticky-record-toolbar')
    page.evaluate_script(<<~JS)
      (() => {
        const r = document.querySelector('#{selector}').getBoundingClientRect();
        return { top: r.top, bottom: r.bottom };
      })()
    JS
  end

  def scroll_to_y(y)
    page.execute_script('window.scrollTo(0, arguments[0])', y)
  end

  def scroll_past_heading
    scroll_to_y(1500)
  end

  def sticky_title_selector
    '.sticky-record-toolbar.is-stuck .sticky-record-toolbar__title'
  end

  {
    'accession' => -> { "/accessions/#{accession.id}/edit" },
    'resource' => -> { "/resources/#{resource.id}/edit" },
    'archival object' => -> { "/resources/#{resource.id}/edit#tree::archival_object_#{archival_object.id}" },
    'digital object' => -> { "/digital_objects/#{digital_object.id}/edit" },
    'digital object component' => -> { "/digital_objects/#{digital_object.id}/edit#tree::digital_object_component_#{digital_object_component.id}" }
  }.each do |label, path|
    describe "on the #{label} edit page" do
      before do
        visit instance_exec(&path)
        expect(page).to have_css('.sticky-record-toolbar h2, .record-pane h2', text: title)
        wait_for_ajax
      end

      it 'pins the toolbar to the top of the viewport on scroll' do
        scroll_past_heading
        expect(page).to have_css('.sticky-record-toolbar')
        expect(toolbar_rect['top']).to eq(0)
      end

      it 'shows the sticky record title only once the heading has scrolled out of view' do
        expect(page).not_to have_css(sticky_title_selector)

        scroll_past_heading
        expect(page).to have_css(sticky_title_selector, text: title)

        scroll_to_y(0)
        expect(page).not_to have_css(sticky_title_selector)
      end

      it 'keeps the sticky record title out of the accessibility tree and free of duplicate ids' do
        sticky_title = find('.sticky-record-toolbar__title', visible: :all)
        aggregate_failures do
          expect(sticky_title['aria-hidden']).to eq('true')
          expect(sticky_title).not_to have_css('[id]', visible: :all)
          expect(page).to have_css('.record-pane h2', count: 1)
        end
      end

      it 'offers Save and Cancel in the toolbar and no bottom form actions' do
        within('.record-toolbar') do
          expect(page).to have_button('Save')
          expect(page).to have_link('Cancel')
        end
        expect(page).not_to have_css('.record-pane .form-actions')
      end
    end
  end

  describe 'on the resource edit page' do
    before do
      visit "/resources/#{resource.id}/edit"
      expect(page).to have_css('.record-pane h2', text: title)
      wait_for_ajax
    end

    context 'with unsaved changes' do
      before do
        fill_in 'resource_title_', with: "#{title} edited"
        expect(page).to have_css('#record-toolbar-alert', visible: true)
      end

      it 'keeps the sticky record title below the alert' do
        scroll_past_heading
        expect(page).to have_css(sticky_title_selector)

        alert = toolbar_rect('#record-toolbar-alert')
        sticky_title = toolbar_rect('.sticky-record-toolbar__title')
        expect(sticky_title['top']).to be >= alert['bottom'] - 1
      end
    end

    context 'when the window is resized' do
      it 'places the sticky record title flush under a toolbar that has wrapped' do
        wide_height = toolbar_rect('.record-toolbar').then { |r| r['bottom'] - r['top'] }

        page.current_window.resize_to(900, 600)
        narrow = toolbar_rect('.record-toolbar')
        skip 'toolbar did not wrap at this width' unless narrow['bottom'] - narrow['top'] > wide_height + 1

        width = page.evaluate_script('window.innerWidth')
        scroll_past_heading
        expect(page).to have_css(sticky_title_selector), "sticky record title not visible at innerWidth #{width}"

        sticky_title = toolbar_rect('.sticky-record-toolbar__title')
        toolbar = toolbar_rect('.record-toolbar')
        expect((sticky_title['top'] - toolbar['bottom']).abs).to be <= 1
      end

      it 'still shows the sticky record title at the right scroll point' do
        page.current_window.resize_to(800, 600)
        page.current_window.resize_to(1200, 600)
        scroll_past_heading
        expect(page).to have_css(sticky_title_selector)
        scroll_to_y(0)
        expect(page).not_to have_css(sticky_title_selector)
      end

      it 'is not sticky below the tablet breakpoint' do
        page.current_window.resize_to(700, 600)
        position = page.evaluate_script(
          "getComputedStyle(document.querySelector('.sticky-record-toolbar')).position"
        )
        expect(position).not_to eq('sticky')
      end
    end

    context 'when jumping to a sidebar anchor' do
      it 'lands below the toolbar and sticky record title' do
        scroll_to_y(0)
        link = first('#archivesSpaceSidebar a[href^="#"]:not([href="#"])', minimum: 0) ||
               all('#archivesSpaceSidebar a[href^="#"]').last
        skip 'no sidebar anchor available' unless link
        anchor = link[:href][/#.+/]
        link.click

        sticky = toolbar_rect('.sticky-record-toolbar')
        target = page.evaluate_script(
          "document.querySelector('#{anchor}').getBoundingClientRect().top"
        )
        expect(target).to be >= sticky['bottom'] - 1
      end
    end
  end

  describe 'on the accession edit page' do
    before do
      visit "/accessions/#{accession.id}"
      click_on 'Edit'
      expect(page).to have_css('.record-pane h2', text: title)
    end

    it 'saves from the toolbar' do
      fill_in 'accession_title_', with: "#{title} saved"
      within('.record-toolbar') { click_button 'Save' }
      expect(page).to have_css('h2', text: "#{title} saved")
    end

    it 'cancels from the toolbar without an unsaved-changes prompt' do
      fill_in 'accession_title_', with: "#{title} discarded"
      within('.record-toolbar') { click_on 'Cancel' }
      expect(page).to have_current_path("/accessions/#{accession.id}")
      expect(page).to have_css('h2', text: title)
    end
  end

  describe 'saving from further down a tree record' do
    it 'scrolls the success message into view below the toolbar' do
      visit "/resources/#{resource.id}/edit"
      wait_for_infinite_tree_loaded

      fill_in 'resource_title_', with: "#{title} saved"
      scroll_past_heading
      within('.record-toolbar') { click_button 'Save' }

      expect(page).to have_css('.alert-success')
      toolbar_bottom = toolbar_rect['bottom']
      alert_rect = toolbar_rect('.alert-success')
      aggregate_failures do
        expect(alert_rect['top']).to be >= toolbar_bottom - 1
        expect(alert_rect['bottom']).to be <= page.evaluate_script('window.innerHeight')
      end
    end
  end

  describe 'on new record pages' do
    it 'keeps the bottom Save and Cancel buttons' do
      visit '/accessions/new'
      expect(page).to have_css('.form-actions .btn-cancel')
      expect(page).to have_css('.form-actions button[type=submit]')
    end
  end

  describe 'after switching tree nodes' do
    it 'refreshes a single sticky record title with the new title' do
      archival_object
      visit "/resources/#{resource.id}/edit"
      wait_for_infinite_tree_loaded

      page.execute_script("window.location.hash = 'tree::archival_object_#{archival_object.id}'")
      wait_for_infinite_tree_current_node(archival_object.uri)

      scroll_past_heading
      expect(page).to have_css(sticky_title_selector, text: archival_object.title)
      expect(page).to have_css('.sticky-record-toolbar__title', count: 1, visible: :all)
    end
  end
end
