RSpec.shared_examples 'a multilingual parent record' do |record_type|
  it 'shows expanded Langauges of Description subrecord on create' do
    click_on 'Create'
    click_on "#{record_type.split('_').map(&:capitalize).join(' ')}"

    within "#form_#{record_type}" do
      expect(page).to have_text 'Languages of Description'

      within "##{record_type}_lang_descriptions_" do
        expect(page).to have_field('Language', type: 'text', count: 1)
        expect(page).to have_field('Script', type: 'text', count: 1)
        expect(page).to have_css('li.is-representative', count: 1)
        expect(page).to have_css('button.is-representative-label', text: 'Primary Language', count: 1)
      end
    end

    click_on 'Add Language of Description'
    within "##{record_type}_lang_descriptions_" do
      expect(page).to have_field('Language', type: 'text', count: 2)
      expect(page).to have_field('Script', type: 'text', count: 2)
      expect(page).to have_css('li.is-representative', count: 1)
      expect(page).to have_css('button.is-representative-label', text: 'Primary Language', count: 1)
      expect(page).to have_css('button.is-representative-toggle', text: 'Make Primary Language', count: 1)
    end
  end
end

RSpec.shared_examples 'a non-multilingual parent record' do |record_type|
  it 'does not show Langauges of Description subrecord on create' do
    click_on 'Create'
    click_on "#{record_type.split('_').map(&:capitalize).join(' ')}"

    within "#form_#{record_type}" do
      expect(page).not_to have_text 'Languages of Description'
    end
  end
end
