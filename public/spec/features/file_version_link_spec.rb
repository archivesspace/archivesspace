require 'spec_helper'
require 'rails_helper'

describe 'File Version Link', js: true do
  # aka 'generic icon'
  def check_uri_css(uri, css)
    visit(uri)
    expect(page).to have_css(css)
  end

  type_map = {
    'default': '.fa-file-o',
    'moving_image': '.fa-file-video-o',
    'sound_recording': '.fa-file-audio-o',
    'sound_recording_musical': '.fa-file-audio-o',
    'sound_recording_nonmusical': '.fa-file-audio-o',
    'still_image': '.fa-file-image-o',
    'text': '.fa-file-text-o'
  }

  before(:all) do
    file_base = 'https://example.com/fv'

    @do1 = create(
      :digital_object,
      publish: true,
      digital_object_type: 'still_image',
      file_versions: [
        {
          publish: true,
          file_uri: file_base + '0.jpg',
          file_format_name: 'jpeg'
        },
        {
          publish: true,
          file_uri: file_base + '1.jpg',
          file_format_name: 'jpeg'
        },
        {
          publish: false,
          file_uri: file_base + '2.jpg',
          file_format_name: 'jpeg'
        }
      ]
    )
    @do2 = create(
      :digital_object,
      publish: true,
      digital_object_type: 'still_image',
      file_versions: [
        {
          publish: true,
          file_uri: file_base + '0.gif',
          file_format_name: 'gif'
        },
        {
          publish: true,
          file_uri: file_base + '1.gif',
          file_format_name: 'gif'
        },
        {
          publish: false,
          file_uri: file_base + '2.gif',
          file_format_name: 'gif'
        }
      ]
    )
    @do3 = create(
      :digital_object,
      publish: true,
      digital_object_type: 'sound_recording',
      file_versions: [
        {
          publish: true,
          file_uri: file_base + '0.mp3',
          file_format_name: 'mp3'
        },
        {
          publish: true,
          file_uri: file_base + '1.mp3',
          file_format_name: 'mp3'
        },
        {
          publish: false,
          file_uri: file_base + '2.mp3',
          file_format_name: 'mp3'
        }
      ]
    )
    @do_unpublished = create(
      :digital_object,
      publish: false,
      file_versions: [
        {
          publish: true,
          file_uri: 'http://example.com',
        }
      ]
    )
    @resource = create(:resource, publish: true,
                       instances: [build(:instance_digital, digital_object: { ref: @do1.uri }), build(:instance_digital, digital_object: { ref: @do2.uri }), build(:instance_digital, digital_object: { ref: @do3.uri })])
    @resource_w_unpub_do = create(:resource, publish: true,
                                  instances: [build(:instance_digital, digital_object: { ref: @do_unpublished.uri })])
    @aobj = create(:archival_object, publish: true,
                       resource: { 'ref' => @resource.uri },
                       instances: [build(:instance_digital, digital_object: { ref: @do1.uri }), build(:instance_digital, digital_object: { ref: @do2.uri })])
    @aobj_w_unpub_do = create(:archival_object, publish: true,
                              resource: { 'ref' => @resource_w_unpub_do.uri },
                              instances: [build(:instance_digital, digital_object: { ref: @do_unpublished.uri })])

    @do_movie = create(:digital_object, publish: true, digital_object_type: 'moving_image', file_versions: [{publish: true, file_uri: file_base + '0.avi', file_format_name: 'avi'}])
    @do_sound1 = create(:digital_object, publish: true, digital_object_type: 'sound_recording', file_versions: [{publish: true, file_uri: file_base + '0.aiff', file_format_name: 'aiff'}])
    @do_sound2 = create(:digital_object, publish: true, digital_object_type: 'sound_recording_musical', file_versions: [{publish: true, file_uri: file_base + '0.mp3', file_format_name: 'mp3'}])
    @do_sound3 = create(:digital_object, publish: true, digital_object_type: 'sound_recording_nonmusical', file_versions: [{publish: true, file_uri: file_base + '0.mp3', file_format_name: 'mp3'}])
    @do_image = create(:digital_object, publish: true, digital_object_type: 'still_image', file_versions: [{publish: true, file_uri: file_base + '0.tiff', file_format_name: 'tiff'}])
    @do_text = create(:digital_object, publish: true, digital_object_type: 'text', file_versions: [{publish: true, file_uri: file_base + '0.txt', file_format_name: 'txt'}])
    @do_default = create(:digital_object, publish: true, file_versions: [{publish: true, file_uri: file_base + '0.pdf', file_format_name: 'pdf'}])

    run_indexers
  end

  it "shows a link to only the most recently published file version on a digital object's page" do
    visit(@do1.uri)
    expect(page.all('.available-digital-objects > .objectimage').length).to eq 1
    expect(page).to have_css('.available-digital-objects .external-digital-object__link[href="https://example.com/fv1.jpg"]')
  end

  it "shows links to all linked digital objects' most recently published file versions on a resource's page" do
    visit(@resource.uri)
    expect(page.all('.available-digital-objects > .objectimage').length).to eq 3
    expect(page).to have_css('.available-digital-objects .external-digital-object__link[href="https://example.com/fv1.jpg"]')
    expect(page).to have_css('.available-digital-objects .external-digital-object__link[href="https://example.com/fv1.gif"]')
    expect(page).to have_css('.available-digital-objects .external-digital-object__link[href="https://example.com/fv1.mp3"]')
  end

  it "shows links to all linked digital objects' most recently published file versions on an archival object's page" do
    visit(@aobj.uri)
    expect(page.all('.available-digital-objects > .objectimage').length).to eq 2
    expect(page).to have_css('.available-digital-objects .external-digital-object__link[href="https://example.com/fv1.jpg"]')
    expect(page).to have_css('.available-digital-objects .external-digital-object__link[href="https://example.com/fv1.gif"]')
  end

  it "is not shown on a resource page when a linked digital object is unpublished "\
     "with published file versions" do
    visit(@resource_w_unpub_do.uri)
    expect(page).not_to have_css('.available-digital-objects .external-digital-object__link')
  end

  it "is not shown on an archival object page when a linked digital object is unpublished "\
      "with published file versions" do
    visit(@aobj_w_unpub_do.uri)
    expect(page).not_to have_css('.available-digital-objects .external-digital-object__link')
  end

  it "shows the correct icon for digital_object_type moving_image" do
    check_uri_css(@do_movie.uri, type_map[:moving_image])
  end

  it "shows the correct icon for digital_object_type sound_recording" do
    check_uri_css(@do_sound1.uri, type_map[:sound_recording])
  end

  it "shows the correct icon for digital_object_type sound_recording_musical" do
    check_uri_css(@do_sound2.uri, type_map[:sound_recording_musical])
  end

  it "shows the correct icon for digital_object_type sound_recording_nonmusical" do
    check_uri_css(@do_sound3.uri, type_map[:sound_recording_nonmusical])
  end

  it "shows the correct icon for digital_object_type still_image" do
    check_uri_css(@do_image.uri, type_map[:still_image])
  end

  it "shows the correct icon for digital_object_type text" do
    check_uri_css(@do_text.uri, type_map[:text])
  end

  it "shows the correct icon for digital_object_type default" do
    check_uri_css(@do_default.uri, type_map[:default])
  end
end
