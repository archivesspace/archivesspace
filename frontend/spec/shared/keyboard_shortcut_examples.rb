# frozen_string_literal: true

# Host groups define the paths the examples visit:
#   edit_path     - the edit form (every record edit page)
#   readonly_path - where Shift+Ctrl+X should land (pages with a readonly view)
# Tree pages get their paths from the 'infinite tree integration hierarchy
# setup' shared context.

# config:
#   path: name of the host group's let that returns the page to visit
#         (default :edit_path)
RSpec.shared_examples 'using the global shortcuts' do |config = {}|
  it 'opens the shortcuts reference and the Browse and Create menus' do
    visit public_send(config.fetch(:path, :edit_path))
    expect(page).not_to have_css('#ASModal', visible: :all)

    page.driver.browser.action.key_down(:shift).send_keys('?').key_up(:shift).perform
    aggregate_failures do
      expect(page).to have_css('#ASModal', visible: true)
      within '#ASModal' do
        expect(page).to have_content('Shift ?')
        expect(page).to have_content('ESC')
        expect(page).to have_content('Shift Ctrl S')
        expect(page).to have_content('Shift Ctrl X')
        expect(page).to have_content('Shift B')
        expect(page).to have_content('Shift C')
      end
    end

    page.driver.browser.action.send_keys(:escape).perform
    expect(page).not_to have_css('#ASModal', visible: :all)

    page.driver.browser.action.key_down(:shift).send_keys('b').key_up(:shift).perform
    expect(page).to have_css('.browse-container > .dropdown-menu', visible: true)
    page.driver.browser.action.key_down(:shift).send_keys('b').key_up(:shift).perform
    expect(page).to have_css('.browse-container > .dropdown-menu', visible: false)

    page.driver.browser.action.key_down(:shift).send_keys('c').key_up(:shift).perform
    expect(page).to have_css('.create-container > .dropdown-menu', visible: true)
    page.driver.browser.action.key_down(:shift).send_keys('c').key_up(:shift).perform
    expect(page).to have_css('.create-container > .dropdown-menu', visible: false)
  end
end

# config:
#   field:         id of the field to change
#   value:         value to enter (default: a unique string)
#   select:        true when field is a select (value is the option text)
#   saved_message: success message expected after saving; a String, or a
#                  lambda taking the entered value
#   shows_value:   true when the page saved to has no success message and
#                  shows the entered value instead
#   lands_on_readonly_view: true when saving redirects to the readonly view
RSpec.shared_examples 'saving the record with the save shortcut' do |config|
  it 'saves the record with Shift+Ctrl+S' do
    new_value = config[:value] || "Shortcut #{SecureRandom.hex(4)}"

    visit edit_path
    if config[:select]
      select new_value, from: config[:field]
    else
      fill_in config[:field], with: new_value
    end

    press_save_shortcut

    aggregate_failures do
      if config[:saved_message]
        message = config[:saved_message]
        message = message.call(new_value) if message.respond_to?(:call)
        expect(page).to have_css('.alert-success', text: message)
      end
      expect(page).to have_current_path(readonly_path) if config[:lands_on_readonly_view]
      expect(page).to have_text(new_value) if config[:shows_value]
    end
  end
end

# config:
#   field: id of a field on the edit form, which the readonly view lacks
RSpec.shared_examples 'closing the record to its readonly view' do |config|
  it 'closes the record to its readonly view with Shift+Ctrl+X' do
    visit edit_path
    expect(page).to have_field(config[:field])

    press_close_shortcut

    aggregate_failures do
      expect(page).to have_current_path(readonly_path)
      expect(page).to have_no_field(config[:field])
    end
  end
end

RSpec.shared_examples 'closing a form that has no readonly view' do |config|
  it 'leaves the form without showing the record with Shift+Ctrl+X' do
    visit edit_path
    expect(page).to have_css('form.aspace-record-form')

    press_close_shortcut

    aggregate_failures do
      expect(page).to have_current_path(config[:lands_on])
      expect(page).to have_no_css('form.aspace-record-form')
    end
  end
end

RSpec.shared_examples 'reloading a form whose URL has no /edit with the close shortcut' do
  it 'reloads the form with Shift+Ctrl+X' do
    visit edit_path
    page.execute_script("document.body.classList.add('before-close-shortcut')")

    press_close_shortcut

    aggregate_failures do
      expect(page).to have_no_css('body.before-close-shortcut')
      expect(page).to have_current_path(edit_path)
      expect(page).to have_css('form.aspace-record-form')
    end
  end
end

RSpec.shared_examples 'using keyboard shortcuts on an Infinite Tree edit page' do |config|
  it_behaves_like 'using the global shortcuts'

  it 'saves the root record with Shift+Ctrl+S without navigating away from the edit page' do
    new_title = "Shortcut Root #{now}"
    visit "#{edit_path}#{root_hash}"
    wait_for_infinite_tree_loaded
    fill_in config[:root_dirty_field], with: new_title

    wait_for_infinite_tree_record_pane_submit { press_save_shortcut }

    aggregate_failures do
      expect(page).to have_css('#infinite-tree-record-pane .alert-success', text: new_title)
      expect(page).to have_current_path(edit_path)
      expect(page.evaluate_script('window.location.hash')).to eq(root_hash)
      expect(page).to have_field(config[:root_dirty_field], with: new_title)
    end
  end

  it 'saves a child record with Shift+Ctrl+S without navigating away from the edit page' do
    new_title = "Shortcut Child #{now}"
    visit "#{edit_path}#{child_record_hash}"
    wait_for_infinite_tree_loaded
    fill_in config[:child_post_save_field], with: new_title

    wait_for_infinite_tree_record_pane_submit { press_save_shortcut }

    aggregate_failures do
      expect(page).to have_css('#infinite-tree-record-pane .alert-success', text: new_title)
      expect(page).to have_current_path(edit_path)
      expect(page.evaluate_script('window.location.hash')).to eq(child_record_hash)
      expect(page).to have_field(config[:child_post_save_field], with: new_title)
    end
  end

  it 'closes the root record to its readonly view with Shift+Ctrl+X' do
    visit "#{edit_path}#{root_hash}"
    wait_for_infinite_tree_loaded

    press_close_shortcut

    expect(page).to have_current_path(show_path)
    wait_for_infinite_tree_loaded
    aggregate_failures do
      expect(page.evaluate_script('window.location.hash')).to eq(root_hash)
      within '#infinite-tree-record-pane' do
        expect(page).to have_css('h2', text: root_record.title)
        expect(page).to have_no_field(config[:root_dirty_field])
      end
    end
  end

  it 'closes a child record to its readonly view with Shift+Ctrl+X' do
    visit "#{edit_path}#{child_record_hash}"
    wait_for_infinite_tree_loaded

    press_close_shortcut

    expect(page).to have_current_path(show_path)
    wait_for_infinite_tree_loaded
    aggregate_failures do
      expect(page.evaluate_script('window.location.hash')).to eq(child_record_hash)
      within '#infinite-tree-record-pane' do
        expect(page).to have_css('h2', text: child_record.title)
        expect(page).to have_no_field(config[:child_post_save_field])
      end
    end
  end

  if config[:supports_rde]
    it 'does not save the root record with Shift+Ctrl+S while the Rapid Data Entry modal is open' do
      visit "#{edit_path}#{root_hash}"
      wait_for_infinite_tree_loaded
      open_infinite_tree_rapid_data_entry_modal

      start_counting_form_submissions
      press_save_shortcut

      aggregate_failures do
        expect(form_submission_count).to eq(0)
        expect(page).to have_css('#rapidDataEntryModal.show')
      end

      within('#rapidDataEntryModal') { click_on 'Cancel' }
      aggregate_failures do
        expect(page).not_to have_css('#rapidDataEntryModal.show')
        expect(page).not_to have_css('#infinite-tree-record-pane .alert-success')
      end
    end
  end
end
