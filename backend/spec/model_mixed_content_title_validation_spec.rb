# frozen_string_literal: true

require 'spec_helper'

describe 'Mixed content title validation' do
  before(:all) do
    @was_enabled = AppConfig[:allow_mixed_content_title_fields]
    AppConfig[:allow_mixed_content_title_fields] = true
  end

  after(:all) do
    AppConfig[:allow_mixed_content_title_fields] = @was_enabled
  end

  it 'allows valid inline EAD markup in titles' do
    expect {
      Resource.create_from_json(build(:json_resource, title: 'A <emph render="italic">valid</emph> title'))
    }.not_to raise_error

    expect {
      ArchivalObject.create_from_json(build(:json_archival_object, title: 'AO with <title>valid</title> inline'))
    }.not_to raise_error
  end

  it 'rejects malformed inline EAD markup with missing/curly quotes in attributes' do
    bad_title = '<title render=”italic>Title</title>'

    expect {
      Resource.create_from_json(build(:json_resource, title: bad_title))
    }.to raise_error(Sequel::ValidationFailed)

    expect {
      ArchivalObject.create_from_json(build(:json_archival_object, title: bad_title))
    }.to raise_error(Sequel::ValidationFailed)
  end

  it 'rejects malformed attribute assignments without quotes' do
    bad_title = '<emph render=italic>oops</emph>'

    expect {
      Resource.create_from_json(build(:json_resource, title: bad_title))
    }.to raise_error(Sequel::ValidationFailed)
  end

  it 'rejects disallowed HTML tags like script' do
    xss_title = '<script>alert("XSS")</script>'

    expect {
      Resource.create_from_json(build(:json_resource, title: xss_title))
    }.to raise_error(Sequel::ValidationFailed) do |error|
      expect(error.errors[:title]).to include('mixed_content_disallowed_tag')
    end

    expect {
      ArchivalObject.create_from_json(build(:json_archival_object, title: xss_title))
    }.to raise_error(Sequel::ValidationFailed)
  end

  it 'rejects disallowed HTML tags like iframe' do
    bad_title = '<iframe src="http://evil.com"></iframe>'

    expect {
      Resource.create_from_json(build(:json_resource, title: bad_title))
    }.to raise_error(Sequel::ValidationFailed) do |error|
      expect(error.errors[:title]).to include('mixed_content_disallowed_tag')
    end
  end

  it 'rejects disallowed HTML tags like style' do
    bad_title = '<style>body { display: none; }</style>'

    expect {
      Resource.create_from_json(build(:json_resource, title: bad_title))
    }.to raise_error(Sequel::ValidationFailed) do |error|
      expect(error.errors[:title]).to include('mixed_content_disallowed_tag')
    end
  end

  it 'rejects disallowed form elements' do
    bad_title = 'Title with <input type="text" name="evil">'

    expect {
      Resource.create_from_json(build(:json_resource, title: bad_title))
    }.to raise_error(Sequel::ValidationFailed) do |error|
      expect(error.errors[:title]).to include('mixed_content_disallowed_tag')
    end
  end

  it 'rejects malformed script tag (incomplete) as disallowed instead of invalid' do
    bad_title = '<script>alert("XSS")</script'

    expect {
      Resource.create_from_json(build(:json_resource, title: bad_title))
    }.to raise_error(Sequel::ValidationFailed) do |error|
      expect(error.errors[:title]).to include('mixed_content_disallowed_tag')
    end
  end

  it 'allows valid EAD tags that are not in the disallowed list' do
    valid_titles = [
      '<emph render="italic">Emphasized</emph>',
      '<title>Main Title</title>',
      '<lb/>Line break',
      '<p>Paragraph</p>',
      '<span class="test">Span</span>'
    ]

    valid_titles.each do |title|
      expect {
        Resource.create_from_json(build(:json_resource, title: title))
      }.not_to raise_error, "Expected #{title} to be valid"
    end
  end
end
