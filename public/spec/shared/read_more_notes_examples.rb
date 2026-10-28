# frozen_string_literal: true

module ReadMoreNotesInteractionHelpers
  READMORE_TOGGLE_SELECTOR = '[data-js="readmore-toggle"]'

  def readmore_toggle_selector
    READMORE_TOGGLE_SELECTOR
  end

  def test_expand_collapse(content, button, see_more, see_less, mode = 'click')
    initial_height = page.evaluate_script('arguments[0].clientHeight;', content.native)

    if mode == 'click'
      button.click
    elsif mode == 'keyboard'
      button.send_keys(:space)
    end

    expect(page.evaluate_script('arguments[0].clientHeight;', content.native)).to be > initial_height
    expect(see_more).to_not be_visible
    expect(see_less).to be_visible

    if mode == 'click'
      button.click
    elsif mode == 'keyboard'
      button.send_keys(:space)
    end

    expect(page.evaluate_script('arguments[0].clientHeight;', content.native)).to eq(initial_height)
    expect(see_more).to be_visible
    expect(see_less).to_not be_visible

    return unless mode == 'keyboard'

    button.send_keys(:enter)

    expect(page.evaluate_script('arguments[0].clientHeight;', content.native)).to be > initial_height

    button.send_keys(:enter)

    expect(page.evaluate_script('arguments[0].clientHeight;', content.native)).to eq(initial_height)
  end

  def exercise_readmore(scope, index: 0, mode: 'click')
    within(all(scope)[index]) do
      test_expand_collapse(
        find('.readmore__content'),
        find(readmore_toggle_selector),
        find('.readmore__text--more'),
        find('.readmore__text--less', visible: false),
        mode
      )
    end
  end

  def expect_langmaterial_readmore(record_uri:, block_count:, toggle_count:)
    visit(record_uri)
    langmaterial_notes = all('.upper-record-details .langmaterial.single_note')

    expect(langmaterial_notes.length).to eq(block_count)
    expect(langmaterial_notes.count { |note| note.has_css?(readmore_toggle_selector) }).to eq(toggle_count)
  end
end

RSpec.shared_context 'read more notes interaction helpers' do
  include ReadMoreNotesInteractionHelpers
end

RSpec.shared_examples 'showing a readmore button on long multipart notes' do
  include_context 'read more notes interaction helpers'

  it 'shows a readmore button on long multipart notes' do
    visit(record_uri)
    expect(find(long_notes_selector)).to have_css(readmore_toggle_selector, count: long_toggle_count)

    unless short_notes_selector.nil?
      expect(find(short_notes_selector)).to have_no_css(readmore_toggle_selector)
    end
  end
end

RSpec.shared_examples 'showing a readmore button on long lang material notes' do
  include_context 'read more notes interaction helpers'

  it 'shows a readmore button on long lang material notes' do
    expect_langmaterial_readmore(
      record_uri: record_uri,
      block_count: lang_material_block_count,
      toggle_count: readmore_toggle_count
    )
  end
end

RSpec.shared_examples 'showing and hiding long note content' do
  include_context 'read more notes interaction helpers'

  it 'shows and hides long note content' do
    visit(record_uri)
    exercise_readmore(readmore_scope, index: readmore_index, mode: interaction_mode)
  end
end

RSpec.shared_examples 'exercising multiple readmore toggles for the same note type' do
  include_context 'read more notes interaction helpers'

  it 'expands and collapses the associated long note content for each readmore toggle' do
    skip 'record has fewer than two readmore toggles' if readmore_toggle_count < 2

    visit(record_uri)
    readmore_toggle_count.times do |index|
      exercise_readmore(readmore_scope, index: index, mode: interaction_mode)
    end
  end
end

RSpec.shared_examples 'toggling aria-expanded when readmore state changes' do
  include_context 'read more notes interaction helpers'

  it 'toggles the aria-expanded attribute on the button when state changes' do
    visit(record_uri)

    within(all(readmore_scope)[readmore_index]) do
      button = find("#{readmore_toggle_selector}[aria-expanded=\"false\"]")
      see_more = find('.readmore__text--more')
      see_less = find('.readmore__text--less', visible: false)

      expect(button[:'aria-label']).to be_nil

      see_more.click

      expect(button[:'aria-expanded']).to eq('true')

      see_less.click

      expect(button[:'aria-expanded']).to eq('false')
    end
  end
end

RSpec.shared_examples 'using native readmore buttons with unique ids and aria-controls' do
  include_context 'read more notes interaction helpers'

  it 'uses native buttons with unique ids and matching aria-controls' do
    visit(record_uri)
    readmore_regions = all(readmore_scope)
    expect(readmore_regions.length).to eq(readmore_toggle_count)

    ids = readmore_regions.map do |readmore|
      within(readmore) do
        button = find("button.readmore__toggle#{readmore_toggle_selector}")
        content = find('.readmore__content')

        expect(readmore).to have_no_css('input.readmore__state', visible: :all)
        expect(readmore).to have_no_css('label[for]', visible: :all)
        expect(button[:type]).to eq('button')
        expect(button[:'aria-controls']).to eq(content[:id])
        expect(content[:role]).to be_nil
        expect(content[:'aria-labelledby']).to be_nil

        {
          toggle_id: button[:id],
          content_id: content[:id]
        }
      end
    end

    all_ids = ids.flat_map { |id_set| id_set.values }
    expect(all_ids).to eq(all_ids.uniq)

    return unless readmore_toggle_count > 1

    expect(ids[0][:content_id]).not_to eq(ids[1][:content_id])
  end
end
