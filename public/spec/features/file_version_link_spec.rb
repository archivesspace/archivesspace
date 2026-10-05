require 'spec_helper'
require 'rails_helper'

describe 'File Version Link', js: true do
  # aka 'generic icon'
  def check_uri_css(uri, css)
    visit(uri)
    expect(page).to have_css(css)
  end

  type_map = {
    'default': '.pui-thumbnail .pui-thumbnail-icon.fa.fa-file-o',
    'moving_image': '.pui-thumbnail .pui-thumbnail-icon.fa.fa-file-video-o',
    'sound_recording': '.pui-thumbnail .pui-thumbnail-icon.fa.fa-file-audio-o',
    'sound_recording_musical': '.pui-thumbnail .pui-thumbnail-icon.fa.fa-file-audio-o',
    'sound_recording_nonmusical': '.pui-thumbnail .pui-thumbnail-icon.fa.fa-file-audio-o',
    'still_image': '.pui-thumbnail .pui-thumbnail-icon.fa.fa-file-image-o',
    'text': '.pui-thumbnail .pui-thumbnail-icon.fa.fa-file-text-o'
  }

  before(:all) do
    file_base = 'https://example.com/fv'

    @do_movie = create(:digital_object, publish: true, digital_object_type: 'moving_image', file_versions: [{publish: true, is_display_link: true, file_uri: file_base + '0.avi', file_format_name: 'avi'}])
    @do_sound1 = create(:digital_object, publish: true, digital_object_type: 'sound_recording', file_versions: [{publish: true, is_display_link: true, file_uri: file_base + '0.aiff', file_format_name: 'aiff'}])
    @do_sound2 = create(:digital_object, publish: true, digital_object_type: 'sound_recording_musical', file_versions: [{publish: true, is_display_link: true, file_uri: file_base + '0.mp3', file_format_name: 'mp3'}])
    @do_sound3 = create(:digital_object, publish: true, digital_object_type: 'sound_recording_nonmusical', file_versions: [{publish: true, is_display_link: true, file_uri: file_base + '0.mp3', file_format_name: 'mp3'}])
    @do_image = create(:digital_object, publish: true, digital_object_type: 'still_image', file_versions: [{publish: true, is_display_link: true, file_uri: file_base + '0.tiff', file_format_name: 'tiff'}])
    @do_text = create(:digital_object, publish: true, digital_object_type: 'text', file_versions: [{publish: true, is_display_link: true, file_uri: file_base + '0.txt', file_format_name: 'txt'}])
    @do_default = create(:digital_object, publish: true, file_versions: [{publish: true, is_display_link: true, file_uri: file_base + '0.pdf', file_format_name: 'pdf'}])

    run_indexers
  end

  it "links the generic icon to the display link file version" do
    check_uri_css(@do_movie.uri, ".pui-thumbnail a[href='https://example.com/fv0.avi'] .pui-thumbnail-icon.fa-file-video-o")
  end

  it "shows the thumbnail for digital_object_type moving_image" do
    check_uri_css(@do_movie.uri, type_map[:moving_image])
  end

  it "shows the thumbnail for digital_object_type sound_recording" do
    check_uri_css(@do_sound1.uri, type_map[:sound_recording])
  end

  it "shows the thumbnail for digital_object_type sound_recording_musical" do
    check_uri_css(@do_sound2.uri, type_map[:sound_recording_musical])
  end

  it "shows the thumbnail for digital_object_type sound_recording_nonmusical" do
    check_uri_css(@do_sound3.uri, type_map[:sound_recording_nonmusical])
  end

  it "shows the thumbnail for digital_object_type still_image" do
    check_uri_css(@do_image.uri, type_map[:still_image])
  end

  it "shows the thumbnail for digital_object_type text" do
    check_uri_css(@do_text.uri, type_map[:text])
  end

  it "shows the thumbnail for digital_object_type default" do
    check_uri_css(@do_default.uri, type_map[:default])
  end
end
