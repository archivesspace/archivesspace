require 'spec_helper'
require 'rails_helper'

def test_expand_collapse(content, label, see_more, see_less, mode = 'click')
  initial_height = page.evaluate_script("arguments[0].clientHeight;", content.native)

  if mode == 'click'
    label.click
  elsif mode == 'keyboard'
    label.send_keys(:tab)
    label.send_keys(:space)
  end

  expect(page.evaluate_script("arguments[0].clientHeight;", content.native)).to be > initial_height
  expect(see_more).to_not be_visible
  expect(see_less).to be_visible

  if mode == 'click'
    label.click
  elsif mode == 'keyboard'
    label.send_keys(:tab)
    label.send_keys(:space)
  end

  expect(page.evaluate_script("arguments[0].clientHeight;", content.native)).to eq(initial_height)
  expect(see_more).to be_visible
  expect(see_less).to_not be_visible

  if mode == 'keyboard'
    label.send_keys(:tab)
    label.send_keys(:enter)

    expect(page.evaluate_script("arguments[0].clientHeight;", content.native)).to be > initial_height

    label.send_keys(:tab)
    label.send_keys(:enter)

    expect(page.evaluate_script("arguments[0].clientHeight;", content.native)).to eq(initial_height)
  end
end

describe 'Read More Notes', js: true do

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
    long_second_level_note = build(:json_note_singlepart,
      content: ['a' * long_chars_count],
      type: 'abstract',
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
      notes: [ long_top_level_note, short_top_level_note, long_second_level_note ]
    )
    @ao = create(:archival_object,
      resource: { ref: @resource.uri },
      title: "Archival Object with inherited long note #{@now}",
      publish: true,
    )

    run_indexers
  end

  before(:each) do
    visit(@resource.uri)
  end

  it "shows on top-level notes of a Resource Collection Overview when the note exceeds AppConfig[:pui_readmore_max_characters]" do
    scope_and_contents = find('.upper-record-details .abstract.single_note')
    bioghist = find('.upper-record-details .bioghist.single_note')

    expect(scope_and_contents).to have_css('[data-js="readmore"]', count: 2)
    expect(bioghist).to_not have_css('[data-js="readmore"]')
  end

  it "expands and collapses when the related controls are clicked" do
    scope_and_contents_read_mores = all('.upper-record-details .abstract.single_note [data-js="readmore"]')

    within(scope_and_contents_read_mores[0]) do
      content = find('.upper-record-details .abstract.single_note .readmore__content')
      label = find('.upper-record-details .abstract.single_note .readmore__label')
      see_more = find('.upper-record-details .abstract.single_note .readmore__label--more')
      see_less = find('.upper-record-details .abstract.single_note .readmore__label--less', visible: false)

      test_expand_collapse(content, label, see_more, see_less)
    end
  end

  it 'behaves as expected when there are multiple long notes of the same note type' do
    scope_and_contents_read_mores = all('.upper-record-details .abstract.single_note [data-js="readmore"]')

    within(scope_and_contents_read_mores[0]) do
      content = find('.upper-record-details .abstract.single_note .readmore__content')
      label = find('.upper-record-details .abstract.single_note .readmore__label')
      see_more = find('.upper-record-details .abstract.single_note .readmore__label--more')
      see_less = find('.upper-record-details .abstract.single_note .readmore__label--less', visible: false)

      test_expand_collapse(content, label, see_more, see_less)
    end

    within(scope_and_contents_read_mores[1]) do
      content = find('.upper-record-details .abstract.single_note .readmore__content')
      label = find('.upper-record-details .abstract.single_note .readmore__label')
      see_more = find('.upper-record-details .abstract.single_note .readmore__label--more')
      see_less = find('.upper-record-details .abstract.single_note .readmore__label--less', visible: false)

      test_expand_collapse(content, label, see_more, see_less)
    end
  end

  it "expands and collapses when Enter or Space keys are pressed after the related controls are tabbed to" do
    scope_and_contents_read_mores = all('.upper-record-details .abstract.single_note [data-js="readmore"]')

    within(scope_and_contents_read_mores[0]) do
      content = find('.upper-record-details .abstract.single_note .readmore__content')
      label = find('.upper-record-details .abstract.single_note .readmore__label')
      see_more = find('.upper-record-details .abstract.single_note .readmore__label--more')
      see_less = find('.upper-record-details .abstract.single_note .readmore__label--less', visible: false)

      test_expand_collapse(content, label, see_more, see_less, 'keyboard')
    end
  end

  it "toggles the aria-expanded attribute on the state element when state changes" do
    scope_and_contents_read_mores = all('.upper-record-details .abstract.single_note [data-js="readmore"]')

    within(scope_and_contents_read_mores[0]) do
      state = find('.upper-record-details .abstract.single_note .readmore__state[aria-expanded="false"]')
      see_more = find('.upper-record-details .abstract.single_note .readmore__label--more')
      see_less = find('.upper-record-details .abstract.single_note .readmore__label--less', visible: false)

      see_more.click

      expect(state[:'aria-expanded']).to eq('true')

      see_less.click

      expect(state[:'aria-expanded']).to eq('false')
    end
  end

  it "does not show on second-level notes of a Resource Collection Overview when the note exceeds AppConfig[:pui_readmore_max_characters]" do
    abstract = find('.acc_holder .abstract.single_note')

    expect(abstract).to_not have_css('[data-js="readmore"]')
  end

  it "shows on the top-level notes of an Archival Object when the note exceeds AppConfig[:pui_readmore_max_characters]" do
    visit(@ao.uri)
    scope_and_contents = find('.upper-record-details .abstract.single_note')

    expect(scope_and_contents).to have_css('[data-js="readmore"]', count: 2)
  end

  it "does not show on a Resource Collection Organization when the note exceeds AppConfig[:pui_readmore_max_characters]" do
    click_on('Collection Organization')
    scope_and_contents = find('.abstract.single_note')

    expect(scope_and_contents).to_not have_css('[data-js="readmore"]')
  end
end
