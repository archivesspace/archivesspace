# frozen_string_literal: true

# Shared examples for linker accessibility testing across 4 linker states:
#
# 1. Empty - linker exposed on edit form with no value
# 2. Dropdown open - dropdown button clicked, menu visible
# 3. Search results showing - text input has value, listbox displaying results
# 4. Linked record selected - linker has an existing linked record value
#
# Required lets in the including context:
# - let(:linker_wrapper_selector) { String } - CSS selector for the .linker-wrapper element
# - let(:navigate_to_empty_linker) { Proc } - navigates to page and exposes empty linker
# - let(:search_term) { String } - text to type for triggering search results
# - let(:searchable_record) { Object } - record that will appear in search results
# - let(:record_with_link) { Object } - record with an existing link (triggers creation)
# - let(:navigate_to_linked_record) { Proc } - navigates to edit form for record with link
#
# Optional lets:
# - let(:dropdown_toggle_selector) { String } - custom dropdown selector
#   (default: '.input-group-append > .dropdown-toggle')

RSpec.shared_examples 'linker accessibility states' do
  context 'when linker is empty' do
    before do
      navigate_to_empty_linker.call
      wait_for_linker_ready
    end

    it 'is axe clean' do
      within_linker_container do
        expect(page).to be_axe_clean.within(linker_wrapper_selector)
      end
    end
  end

  context 'when dropdown menu is expanded' do
    before do
      navigate_to_empty_linker.call
      wait_for_linker_ready
      open_linker_dropdown
    end

    it 'is axe clean' do
      within_linker_container do
        expect(page).to be_axe_clean.within(linker_wrapper_selector)
      end
    end
  end

  context 'when search results are displayed' do
    before do
      searchable_record
      run_index_round
      navigate_to_empty_linker.call
      wait_for_linker_ready
      trigger_search_results
    end

    it 'is axe clean for the listbox' do
      listbox_selector = full_listbox_selector
      expect(page).to have_css("#{listbox_selector} li", visible: :all)
      expect(page)
        .to be_axe_clean
        .checking_only(
          :'aria-allowed-attr',
          :'aria-required-attr',
          :'aria-required-children'
        )
        .within(listbox_selector)
    end
  end

  context 'when linker has an existing linked record' do
    before do
      record_with_link
      navigate_to_linked_record.call
      wait_for_linker_ready
    end

    it 'is axe clean' do
      within_linker_container do
        expect(page).to be_axe_clean.within(linker_wrapper_selector)
      end
    end
  end

  private

  def dropdown_toggle_selector_value
    if respond_to?(:dropdown_toggle_selector)
      dropdown_toggle_selector
    else
      '.input-group-append > .dropdown-toggle'
    end
  end

  def within_linker_container(&block)
    if respond_to?(:linker_container_selector)
      within(linker_container_selector, &block)
    else
      yield
    end
  end

  # The linker is only ready for axe once tokeninput has set it up (linker.js
  # adds role=searchbox in a setTimeout) and, for a newly added subrecord, once
  # subrecord.crud's fadeIn has finished. Selenium counts a partly faded-in
  # element as visible, and axe's color-contrast rule factors in its opacity.
  # The searchbox check uses visible: :all because tokeninput hides the search
  # input once a linker has reached its token limit (e.g. an existing link).
  def wait_for_linker_ready
    within_linker_container do
      expect(page).to have_css(
        "#{linker_wrapper_selector} input[role='searchbox']",
        visible: :all
      )
    end

    page.document.synchronize do
      unless page.evaluate_script('jQuery(":animated").length === 0')
        raise Capybara::ExpectationNotMet, 'linker subrecord is still animating'
      end
    end
  end

  def open_linker_dropdown
    within_linker_container do
      find("#{linker_wrapper_selector} #{dropdown_toggle_selector_value}").click
    end
  end

  def trigger_search_results
    within_linker_container do
      field = find("#{linker_wrapper_selector} input[role='searchbox']")
      field.send_keys(search_term)
    end
    expect(page).to have_css(full_listbox_selector)
  end

  def full_listbox_selector
    base = "#{linker_wrapper_selector} ul[role='listbox']"
    if respond_to?(:linker_container_selector)
      "#{linker_container_selector} #{base}"
    else
      base
    end
  end
end
