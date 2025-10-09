# frozen_string_literal: true

# Used for expand/collapse components.
# The spec file must define:
# - let(:control_element_selector) - CSS selector for the control element
# - let(:controlled_element_id) - HTML id of the controlled element
RSpec.shared_examples 'having an accessible exapandable element' do
  context 'when not expanded' do
    describe 'the control element' do
      let(:control_element) { find(control_element_selector) }

      it 'has aria-expanded attribute set to false' do
        expect(control_element['aria-expanded']).to eq 'false'
      end

      it 'has aria-controls attribute set to the id of the controlled element' do
        expect(control_element['aria-controls']).to eq controlled_element_id
      end
    end

    describe 'the controlled element' do
      it 'is not visible' do
        expect(page).to have_css("##{controlled_element_id}", visible: false)
      end
    end
  end

  context 'when expanded' do
    before(:each) do
      find(control_element_selector).click
      wait_for_jquery
    end

    describe 'the control element' do
      let(:control_element) { find(control_element_selector) }

      it 'has aria-expanded attribute set to true' do
        expect(control_element['aria-expanded']).to eq 'true'
      end

      it 'has aria-controls attribute set to the id of the controlled element' do
        expect(control_element['aria-controls']).to eq controlled_element_id
      end
    end

    describe 'the controlled element' do
      it 'is visible' do
        expect(page).to have_css("##{controlled_element_id}", visible: true)
      end
    end
  end
end
