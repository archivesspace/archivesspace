require 'spec_helper'
require 'rails_helper'

describe 'Citation dialog modal', js: true do
  before(:each) do
    visit('/')
    click_link 'Collections'
    expect(current_path).to eq ('/repositories/resources')
    resource = first("a.record-title")
    visit(resource['href'])

    expect(page).to have_css('#cite_modal', visible: false)
    dialog_button = page.find('form#cite_sub > button[type="submit"]')
    dialog_button.click
    expect(page).to have_css('#cite_modal', visible: true)
  end

  it 'should copy each citation to clipboard on button clicks' do
    # Test copy-to-clipboard by keyboard-pasting the clipboard
    # into temporary input elements.
    item_text = page.find('#item_citation').text
    item_description_text = page.find('#item_description_citation').text

    execute_script("var $modalBody = $('#cite_modal .modal-body');var tempItemInput = document.createElement('input');tempItemInput.id = 'tempItemInput';var tempItemDescInput = document.createElement('input');tempItemDescInput.id = 'tempItemDescInput';$modalBody.append(tempItemInput);$modalBody.append(tempItemDescInput);")

    cite_item_btn = page.find('#copy_item_citation')
    cite_item_btn.click
    item_input = page.find('#tempItemInput')
    item_input.click
    if page.driver.browser.capabilities.platform_name =~ /^mac/
      item_input.send_keys([:command, 'v'])
    else
      item_input.send_keys([:control, 'v'])
    end
    expect(item_input.value).to eq(item_text)

    cite_item_desc_btn = page.find('#copy_item_description_citation')
    cite_item_desc_btn.click
    item_desc_input = page.find('#tempItemDescInput')
    item_desc_input.click
    if page.driver.browser.capabilities.platform_name =~ /^mac/
      item_desc_input.send_keys([:command, 'v'])
    else
      item_desc_input.send_keys([:control, 'v'])
    end
    expect(item_desc_input.value).to eq(item_description_text)
  end

  it 'should close when the header close button is clicked' do
    header_close_btn = page.find('#cite_modal_header_close')
    header_close_btn.click
    expect(page).to have_css('#cite_modal', visible: false)
  end

  it 'should close when the footer close button is clicked' do
    footer_close_btn = page.find('#cite_modal_footer_close')
    footer_close_btn.click
    expect(page).to have_css('#cite_modal', visible: false)
  end

  it 'should close when the escape key is pressed' do
    dialog = page.find('#cite_modal')
    dialog.send_keys(:escape)
    expect(page).to have_css('#cite_modal', visible: false)
  end

  it 'should close with a click on dialog root outside the `.modal-dialog` content' do
    dialog = page.find('#cite_modal')
    dialog.click
    expect(page).to have_css('#cite_modal', visible: false)
  end

  it 'should have `role` attribute on dialog root' do
    expect(page).to have_css('#cite_modal[role="dialog"]')
  end

  it 'should have `aria-modal` attribute on dialog root' do
    expect(page).to have_css('#cite_modal[aria-modal="true"]')
  end

  it 'should have `aria-labelledby` attribute on dialog root pointing to the first heading' do
    expect(page).to have_css('#cite_modal[aria-labelledby="cite_modalLabel"]')
  end

  it 'should have a header with a heading level 2' do
    expect(page).to have_css('#cite_modal header h2#cite_modalLabel')
  end

  it 'should have a header with a close button with `aria-label` attribute' do
    expect(page).to have_css('#cite_modal header button#cite_modal_header_close[aria-label="Close"]')
  end

  it 'should have a footer with a close button with `aria-label` attribute' do
    expect(page).to have_css('#cite_modal footer button#cite_modal_footer_close[aria-label="Close"]')
  end

  # appears to be working, probably needs to be rewritten for bootstrap 4
  xit 'should restrict focus to dialog and wrap focus within dialog' do
    # The dialog's first close button should get initial focus on open,
    # but Bootstrap mishandles focus so dialog root gets initial focus.
    # Also, Capybara doesn't seem to move focus from the dialog button
    # to the dialog on open like a human-navigated browser, so we have to
    # manually bump initial focus to dialog root.
    # Capybara also does not handle advancing focus backwards well, so
    # we don't test with, eg: `body.send_keys([:shift, :tab])`.
    # The dialog button should get focus on modal close, but Bootstrap
    # mishandles it, so we don't test for it.
    dialog_id = 'cite_modal'
    header_close_btn_id = 'cite_modal_header_close'
    copy_item_btn_id = 'copy_item_citation'
    copy_item_desc_btn_id = 'copy_item_description_citation'
    footer_close_btn_id = 'cite_modal_footer_close'

    body = find('body')
    body.send_keys(:tab)
    expect(page.evaluate_script("document.activeElement.id")).to eq(dialog_id)

    find('#cite_modal').send_keys(:tab)
    expect(page.evaluate_script("document.activeElement.id")).to eq(header_close_btn_id)

    find('#cite_modal_header_close').send_keys(:tab)
    expect(page.evaluate_script("document.activeElement.id")).to eq(copy_item_btn_id)

    find('#copy_item_citation').send_keys(:tab)
    expect(page.evaluate_script("document.activeElement.id")).to eq(copy_item_desc_btn_id)

    find('#copy_item_description_citation').send_keys(:tab)
    expect(page.evaluate_script("document.activeElement.id")).to eq(footer_close_btn_id)

    find('#cite_modal_footer_close').send_keys(:tab)
    expect(page.evaluate_script("document.activeElement.id")).to eq(dialog_id)

    find('#cite_modal').send_keys(:tab)
    expect(page.evaluate_script("document.activeElement.id")).to eq(header_close_btn_id)
  end

end
