# frozen_string_literal: true

# Shared examples for read-only subrecord accordions rendered via
# shared/_accordion_header_toggle.html.erb (layout partial + render :layout).
#
# Required lets in the including context:
# - readonly_page_path { String } - path passed to visit
# - accordion_selector { String } - CSS selector for the accordion container
# - panel_id { String } - id of the collapse panel (no '#')
#
# Optional lets:
# - toggle_selector { String } - defaults to a button with matching aria-controls

RSpec.shared_examples 'read-only accordion header toggle' do
  let(:toggle_selector) do
    "#{accordion_selector} button.accordion-toggle[aria-controls='#{panel_id}']"
  end

  before do
    visit readonly_page_path
  end

  it 'wires an accessible button to the collapse panel' do
    toggle = find(toggle_selector)
    expect(toggle[:type]).to eq('button')
    expect(toggle['aria-controls']).to eq(panel_id)
    expect(toggle['aria-expanded']).to eq('false')
    expect(page).to have_css("##{panel_id}.collapse", visible: :all)
  end

  it 'expands the panel when the header control is clicked' do
    panel_selector = "##{panel_id}"
    expect(page).to have_css(panel_selector, visible: :hidden)
    find(toggle_selector).click
    expect(page).to have_css(panel_selector, visible: :visible)
    expect(find(toggle_selector)[:class]).not_to include('collapsed')
  end

  it 'wraps the toggle in an accordion heading' do
    within(accordion_selector) do
      expect(page).to have_css('h4.accordion-header button.accordion-header-toggle', minimum: 1)
    end
  end
end
