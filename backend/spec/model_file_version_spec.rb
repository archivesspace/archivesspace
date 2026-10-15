require 'spec_helper'

describe 'FileVersion model' do
  {
    :is_display_thumbnail => 'display_thumbnail_must_be_published',
    :is_display_link => 'display_link_must_be_published',
  }.each do |flag, publish_error|
    it "reports '#{publish_error}' for an unpublished file version flagged '#{flag}'" do
      file_version = FileVersion.new(:file_uri => 'http://foo.com/bar', :publish => 0, flag => 1)

      expect(file_version.valid?).to be false
      expect(file_version.errors[flag]).to include(publish_error)
    end
  end
end
