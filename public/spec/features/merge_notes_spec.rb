require 'spec_helper'
require 'rails_helper'

describe 'Merge notes', js: true do
  before(:all) do
    @now = Time.now.to_i

    same_label_notes = [
      build(:json_note_singlepart,
            type: 'abstract',
            label: 'Abstract',
            publish: true,
            content: ["SAME_LABEL_NOTE_ONE_#{@now}"]),
      build(:json_note_singlepart,
            type: 'abstract',
            label: 'Abstract',
            publish: true,
            content: ["SAME_LABEL_NOTE_TWO_#{@now}"]),
      build(:json_note_singlepart,
            type: 'abstract',
            label: 'Abstract',
            publish: true,
            content: ["SAME_LABEL_NOTE_THREE_#{@now}"])
    ]

    differing_label_notes = [
      build(:json_note_singlepart,
            type: 'abstract',
            label: 'Abstract',
            publish: true,
            content: ["DIFFERING_LABEL_NOTE_ONE_#{@now}"]),
      build(:json_note_singlepart,
            type: 'abstract',
            label: 'Summary',
            publish: true,
            content: ["DIFFERING_LABEL_NOTE_TWO_#{@now}"])
    ]

    @same_label_resource = create(:resource,
                                  title: "Resource with same-label abstracts #{@now}",
                                  publish: true,
                                  notes: same_label_notes)

    @differing_label_resource = create(:resource,
                                       title: "Resource with differing-label abstracts #{@now}",
                                       publish: true,
                                       notes: differing_label_notes)

    run_indexers
  end

  describe 'same-type notes with the same label' do
    it 'are merged by concatenating their text' do
      visit @same_label_resource.uri

      within '.upper-record-details .abstract.single_note' do
        expect(page).to have_css('h2', text: 'Abstract', count: 1)
        expect(page).to have_content("SAME_LABEL_NOTE_ONE_#{@now}")
        expect(page).to have_content("SAME_LABEL_NOTE_TWO_#{@now}")
        expect(page).to have_content("SAME_LABEL_NOTE_THREE_#{@now}")
        expect(page).not_to have_css('span.inline-label')
      end
    end
  end

  describe 'same-type notes with different labels' do
    it 'are merged with non-matching labels shown inline' do
      visit @differing_label_resource.uri

      within '.upper-record-details .abstract.single_note' do
        expect(page).to have_css('h2', text: 'Abstract', count: 1)
        expect(page).to have_content("DIFFERING_LABEL_NOTE_ONE_#{@now}")
        expect(page).to have_content("DIFFERING_LABEL_NOTE_TWO_#{@now}")
        expect(page).to have_css('span.inline-label', text: 'Summary')
      end
    end
  end
end
