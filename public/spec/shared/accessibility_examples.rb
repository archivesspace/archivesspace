# frozen_string_literal: true

# Used for expand/collapse components.
# The spec file must define:
# - let(:control_element_selector) - CSS selector for the control element
# - let(:controlled_element_id) - HTML id of the controlled element
RSpec.shared_examples 'having an accessible exapandable element' do
  context 'when not expanded' do
    describe 'the control element' do
      it 'has aria attributes' do
        aggregate_failures 'aria-expanded attribute set to false' do
          expect(page).to have_css("#{control_element_selector}[aria-expanded='false']")
        end

        aggregate_failures 'aria-controls attribute set to the id of the controlled element' do
          expect(page).to have_css("#{control_element_selector}[aria-controls='#{controlled_element_id}']")
        end

        aggregate_failures 'is not visible' do
          expect(page).to have_css("##{controlled_element_id}", visible: false)
        end
      end
    end
  end

  context 'when expanded' do
    before :each do
      find(control_element_selector).click
    end

    describe 'the control element' do
      it 'has aria attributes' do
        aggregate_failures 'aria-expanded attribute set to true' do
          expect(page).to have_css("#{control_element_selector}[aria-expanded='true']")
        end

        aggregate_failures 'is visible' do
          expect(page).to have_css("##{controlled_element_id}", visible: true)
        end

        aggregate_failures 'has aria-controls attribute set to the id of the controlled element' do
          expect(page).to have_css("#{control_element_selector}[aria-controls='#{controlled_element_id}']")
        end
      end
    end
  end
end
