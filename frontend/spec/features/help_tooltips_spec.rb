require 'spec_helper'
require 'rails_helper'

describe 'Help Tooltips', js: true do
  context 'attached to subrecord form headings' do
    before(:each) do
      login_admin
      visit '/resources/new'
      @body = page.find('body')
      @example_heading = page.find('h3.subrecord-form-heading > span', text: 'Languages')
      expect(@body).to_not have_selector('.tooltip:last-child')
    end

    it 'are shown and removed when the heading has mouseenter and mouseleave events respectively' do
      @example_heading.hover
      tooltip = page.find('body > .tooltip:last-child')
      expect(@example_heading['aria-describedby']).to eq(tooltip[:id])
      @body.hover
      expect(page).to_not have_selector('body > .tooltip:last-child')
      expect(@example_heading['aria-describedby']).to be_nil
    end

    it 'are shown and removed when the heading is clicked regardless of a mouseleave event' do
      @example_heading.click
      tooltip = page.find('body > .tooltip:last-child')
      expect(@example_heading['aria-describedby']).to eq(tooltip[:id])
      @body.hover
      expect(page).to have_selector('body > .tooltip:last-child')
      expect(@example_heading['aria-describedby']).to eq(tooltip[:id])
      @example_heading.click
      expect(page).to_not have_selector('body > .tooltip:last-child')
      expect(@example_heading['aria-describedby']).to be_nil
    end

    it 'that are shown from clicking the heading are also removed by clicking the tooltip close button' do
      @example_heading.click
      tooltip = page.find('body > .tooltip:last-child')
      expect(@example_heading['aria-describedby']).to eq(tooltip[:id])
      close_button = tooltip.find('.tooltip-close')
      close_button.click
      expect(page).to_not have_selector('body > .tooltip:last-child')
      expect(@example_heading['aria-describedby']).to be_nil
    end

    it 'that are shown from clicking the heading only have one close button regardless '\
    'of how many other tooltips are open from heading clicks' do
      @example_heading.click
      tooltip = page.find('body > .tooltip:last-child')
      expect(@example_heading['aria-describedby']).to eq(tooltip[:id])
      page.find('h3.subrecord-form-heading > span', text: 'Dates').click
      expect(page).to have_selector('body > .tooltip', count: 2)
      expect(tooltip).to have_selector('.tooltip-close', count: 1)
    end
  end
end
