require 'spec_helper'
require 'rails_helper'

describe 'Read More Notes', js: true do
  include_context 'read more notes interaction helpers'

  before(:all) do
    pui_readmore_max_characters = 1000
    markup_around_note_content = '<p></p>'
    short_chars_count = pui_readmore_max_characters - markup_around_note_content.length
    long_chars_count = short_chars_count + 1

    long_top_level_note = build(:json_note_multipart,
      subnotes: [
        build(:json_note_text, content: 'a' * long_chars_count, :publish => true),
        build(:json_note_text, content: 'b' * long_chars_count, :publish => true)
      ]
    )
    long_accordion_note = build(:json_note_singlepart,
      content: ['a' * long_chars_count],
      type: 'materialspec',
      :publish => true
    )
    short_top_level_note = build(:json_note_multipart,
      type: 'bioghist',
      subnotes: [
        build(:json_note_text, content: 'a' * short_chars_count, :publish => true)
      ]
    )

    @resource = create(:resource,
      title: "Resource with long and short notes #{@now}",
      publish: true,
      notes: [ long_top_level_note, short_top_level_note, long_accordion_note ]
    )
    @ao = create(:archival_object,
      resource: { ref: @resource.uri },
      title: "Archival Object with inherited long note #{@now}",
      publish: true,
    )
    long_langmaterial_note = build(:json_note_langmaterial,
      content: ['a' * long_chars_count],
      publish: true
    )
    second_long_langmaterial_note = build(:json_note_langmaterial,
      content: ['b' * long_chars_count],
      publish: true
    )
    short_langmaterial_note = build(:json_note_langmaterial,
      content: ['a' * short_chars_count],
      publish: true
    )
    @accession = create(:accession,
      title: "Accession with long notes #{@now}",
      publish: true,
      lang_materials: [
        build(:lang_material, notes: [long_langmaterial_note]),
        build(:lang_material, notes: [second_long_langmaterial_note]),
        build(:lang_material, notes: [short_langmaterial_note])
      ]
    )

    run_indexers
  end

  shared_context 'multipart readmore setup' do
    let(:long_notes_selector) { '.upper-record-details .abstract.single_note' }
    let(:long_toggle_count) { 2 }
    let(:readmore_scope) { '.upper-record-details .abstract.single_note .readmore' }
    let(:readmore_index) { 0 }
    let(:readmore_toggle_count) { long_toggle_count }
    let(:interaction_mode) { 'click' }
  end

  context 'Resource Collection Overview' do
    let(:record_uri) { @resource.uri }
    let(:short_notes_selector) { '.upper-record-details .bioghist.single_note' }

    include_context 'multipart readmore setup'

    it_behaves_like 'showing a readmore button on long multipart notes'
    it_behaves_like 'showing and hiding long note content'
    it_behaves_like 'exercising multiple readmore toggles for the same note type'
    it_behaves_like 'toggling aria-expanded when readmore state changes'
    it_behaves_like 'using native readmore buttons with unique ids and aria-controls'

    context 'when activated from the keyboard' do
      let(:interaction_mode) { 'keyboard' }

      it_behaves_like 'showing and hiding long note content'
    end

    it 'does not show on second-level notes when the note exceeds AppConfig[:pui_readmore_max_characters]' do
      visit(record_uri)
      materialspec = find('.acc_holder .materialspec.single_note')

      expect(materialspec).to_not have_css(readmore_toggle_selector)
    end

    it 'does not show on Collection Organization when the note exceeds AppConfig[:pui_readmore_max_characters]' do
      visit("#{record_uri}/collection_organization")
      scope_and_contents = find('#infinite-records-container .abstract.single_note')

      expect(scope_and_contents).to_not have_css(readmore_toggle_selector)
    end
  end

  context 'Archival Objects' do
    let(:record_uri) { @ao.uri }
    let(:short_notes_selector) { nil }

    include_context 'multipart readmore setup'

    it_behaves_like 'showing a readmore button on long multipart notes'
    it_behaves_like 'showing and hiding long note content'
    it_behaves_like 'exercising multiple readmore toggles for the same note type'
    it_behaves_like 'toggling aria-expanded when readmore state changes'
    it_behaves_like 'using native readmore buttons with unique ids and aria-controls'

    context 'when activated from the keyboard' do
      let(:interaction_mode) { 'keyboard' }

      it_behaves_like 'showing and hiding long note content'
    end
  end

  context 'Accessions' do
    let(:record_uri) { @accession.uri }
    let(:readmore_scope) { '.upper-record-details .langmaterial.single_note .readmore' }
    let(:lang_material_block_count) { 3 }
    let(:readmore_toggle_count) { 2 }
    let(:readmore_index) { 0 }
    let(:interaction_mode) { 'click' }

    it_behaves_like 'showing a readmore button on long lang material notes'
    it_behaves_like 'showing and hiding long note content'
    it_behaves_like 'exercising multiple readmore toggles for the same note type'
    it_behaves_like 'toggling aria-expanded when readmore state changes'
    it_behaves_like 'using native readmore buttons with unique ids and aria-controls'

    context 'when activated from the keyboard' do
      let(:interaction_mode) { 'keyboard' }

      it_behaves_like 'showing and hiding long note content'
    end
  end
end
