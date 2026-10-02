require 'spec_helper'

describe 'Thumbnails mixin' do
  describe 'fetch_candidates' do
    let(:file_version_thumbnail) {
      build(:json_file_version, {
        :publish => true,
        :file_uri => generate(:url),
        :use_statement => 'image-thumbnail',
        :file_format_name => 'jpeg',
        :xlink_show_attribute => 'embed',
        :caption => 'Published Thumbnail',
        :is_representative => false,
        :is_display_thumbnail => true,
      })
    }
    let(:file_version_thumbnail_unpublished) {
      build(:json_file_version, {
        :publish => false,
        :file_uri => generate(:url),
        :use_statement => 'image-thumbnail',
        :xlink_show_attribute => 'embed',
        :is_representative => false,
        :caption => 'Unpublished Thumbnail',
      })
    }
    let(:file_version_representative) {
      build(:json_file_version, {
        :publish => true,
        :file_uri => 'http://foo.com/bar/representative',
        :use_statement => 'image-master',
        :is_representative => true,
        :caption => 'Published Representative',
      })
    }
    let(:file_version_something_else) {
      build(:json_file_version, {
        :publish => true,
        :file_uri => generate(:url),
        :use_statement => 'video-streaming',
        :xlink_show_attribute => 'embed',
        :is_representative => false,
        :caption => 'Published Something Else',
      })
    }
    let(:file_version_something_else_unpublished) {
      build(:json_file_version, {
        :publish => false,
        :file_uri => generate(:url),
        :use_statement => 'video-streaming',
        :xlink_show_attribute => 'embed',
        :is_representative => false,
        :caption => 'Unpublished Something Else',
      })
    }
    let!(:digital_object_with_file_versions) {
      create(:json_digital_object,
             publish: true,
             file_versions: [
               file_version_something_else,
               file_version_something_else_unpublished,
               file_version_representative,
               file_version_thumbnail_unpublished,
               file_version_thumbnail
             ])
    }
    let!(:digital_object_component_with_file_versions) {
      create(:json_digital_object_component,
             publish: false,
             file_versions: [
               file_version_something_else,
               file_version_something_else_unpublished,
               file_version_representative,
               file_version_thumbnail_unpublished,
               file_version_thumbnail
             ])
    }
    let!(:digital_object_with_file_versions_unpublished) {
      create(:json_digital_object,
             publish: false,
             file_versions: [
               file_version_something_else,
               file_version_something_else,
               file_version_something_else,
               file_version_something_else
             ])
    }
    let!(:digital_object_with_one_file_version) {
      create(:json_digital_object,
             publish: true,
             file_versions: [
               file_version_representative
             ])
    }

    def check_candidate(candidate, instance_is_representative, digital_object_title, file_version)
      expect(candidate.instance_is_representative).to eq(instance_is_representative)
      expect(candidate.digital_object_title).to eq(digital_object_title)
      expect(candidate.file_version_file_uri).to eq(file_version['file_uri'])
      expect(candidate.file_version_use_statement).to eq(file_version['use_statement'])
      expect(candidate.file_version_file_format_name).to eq(file_version['file_format_name'])
      expect(candidate.file_version_is_representative).to eq(file_version['is_representative'])
      expect(candidate.file_version_is_display_thumbnail).to eq(file_version['is_display_thumbnail'])
      expect(candidate.file_version_caption).to eq(file_version['caption'])
      expect(candidate.file_version_xlink_show_attribute).to eq(file_version['xlink_show_attribute'])
    end


    it 'finds digital object file version candidates' do
      candidates = DigitalObject
                     .fetch_thumbnail_candidates([digital_object_with_file_versions])
                     .fetch(digital_object_with_file_versions.id, [])

      # check only published returned
      expect(candidates.length).to eq(3)

      # check all properties are filled out as expected
      check_candidate(candidates[0], false, digital_object_with_file_versions.title, file_version_something_else)
      check_candidate(candidates[1], false, digital_object_with_file_versions.title, file_version_representative)
      check_candidate(candidates[2], false, digital_object_with_file_versions.title, file_version_thumbnail)
    end

    it 'finds digital object component file version candidates' do
      candidates = DigitalObjectComponent
                     .fetch_thumbnail_candidates([digital_object_component_with_file_versions])
                     .fetch(digital_object_component_with_file_versions.id, [])

      # check only published returned
      expect(candidates.length).to eq(3)

      # check all properties are filled out as expected
      check_candidate(candidates[0], false, digital_object_component_with_file_versions.title, file_version_something_else)
      check_candidate(candidates[1], false, digital_object_component_with_file_versions.title, file_version_representative)
      check_candidate(candidates[2], false, digital_object_component_with_file_versions.title, file_version_thumbnail)
    end

    it 'finds archival object candidates' do
      archival_object = create(:json_archival_object,
                               ref_id: generate(:alphanumstr),
                               instances: [
                                 build(:json_instance_digital, {
                                   digital_object: {
                                     ref: digital_object_with_file_versions.uri,
                                   }
                                 }),
                               ])

      candidates = ArchivalObject
                     .fetch_thumbnail_candidates([archival_object])
                     .fetch(archival_object.id, [])

      # check only published returned
      expect(candidates.length).to eq(3)

      # check all properties are filled out as expected
      check_candidate(candidates[0], false, digital_object_with_file_versions.title, file_version_something_else)
      check_candidate(candidates[1], false, digital_object_with_file_versions.title, file_version_representative)
      check_candidate(candidates[2], false, digital_object_with_file_versions.title, file_version_thumbnail)
    end

    it 'does not find archival object candidates when the digital object is unpublished' do
      archival_object = create(:json_archival_object,
                               ref_id: generate(:alphanumstr),
                               instances: [
                                 build(:json_instance_digital, {
                                   digital_object: {
                                     ref: digital_object_with_file_versions_unpublished.uri,
                                   }
                                 }),
                               ])

      candidates = ArchivalObject
                     .fetch_thumbnail_candidates([archival_object])
                     .fetch(archival_object.id, [])

      # check only published returned
      expect(candidates.length).to eq(0)
    end

    it 'finds resource candidates' do
      resource = create(:json_resource,
                        instances: [
                          build(:json_instance_digital, {
                            digital_object: {
                              ref: digital_object_with_file_versions.uri,
                            }
                          }),
                        ])

      candidates = Resource
                     .fetch_thumbnail_candidates([resource])
                     .fetch(resource.id, [])

      # check only published returned
      expect(candidates.length).to eq(3)

      # check all properties are filled out as expected
      check_candidate(candidates[0], false, digital_object_with_file_versions.title, file_version_something_else)
      check_candidate(candidates[1], false, digital_object_with_file_versions.title, file_version_representative)
      check_candidate(candidates[2], false, digital_object_with_file_versions.title, file_version_thumbnail)
    end

    it 'finds accession candidates' do
      accession = create(:json_accession,
                         instances: [
                           build(:json_instance_digital, {
                             digital_object: {
                               ref: digital_object_with_file_versions.uri,
                             }
                           }),
                         ])

      candidates = Accession
                     .fetch_thumbnail_candidates([accession])
                     .fetch(accession.id, [])

      # check only published returned
      expect(candidates.length).to eq(3)

      # check all properties are filled out as expected
      check_candidate(candidates[0], false, digital_object_with_file_versions.title, file_version_something_else)
      check_candidate(candidates[1], false, digital_object_with_file_versions.title, file_version_representative)
      check_candidate(candidates[2], false, digital_object_with_file_versions.title, file_version_thumbnail)
    end

    it 'finds file_version candidates' do
      file_version = DigitalObject[digital_object_with_one_file_version.id].file_version[0]
      candidates = FileVersion.fetch_thumbnail_candidates([file_version]).fetch(file_version.id, [])
      expect(candidates.length).to eq(1)
      check_candidate(candidates[0], false, nil, file_version_representative)
    end
  end

  let(:thumbnail_candidate) {
    Thumbnails::ThumbnailCandidate.from_hash(
      :instance_is_representative => false,
      :digital_object_title => generate(:alphanumstr),
      :file_version_file_uri => generate(:url),
      :file_version_use_statement => 'image-thumbnail',
      :file_version_file_format_name => 'jpeg',
      :file_version_xlink_show_attribute => 'embed',
      :file_version_is_representative => false,
      :file_version_is_display_thumbnail => false,
      :file_version_caption => generate(:alphanumstr)
    )
  }
  let(:master_candidate) {
    Thumbnails::ThumbnailCandidate.from_hash(
      :instance_is_representative => false,
      :digital_object_title => generate(:alphanumstr),
      :file_version_file_uri => generate(:url),
      :file_version_use_statement => 'image-master',
      :file_version_file_format_name => 'jpeg',
      :file_version_xlink_show_attribute => nil,
      :file_version_is_representative => false,
      :file_version_is_display_thumbnail => false,
      :file_version_caption => generate(:alphanumstr)
    )
  }
  let(:master_thumbnail_candidate) {
    Thumbnails::ThumbnailCandidate.from_hash(
      :instance_is_representative => false,
      :digital_object_title => generate(:alphanumstr),
      :file_version_file_uri => generate(:url),
      :file_version_use_statement => 'image-master',
      :file_version_file_format_name => 'jpeg',
      :file_version_xlink_show_attribute => nil,
      :file_version_is_representative => false,
      :file_version_is_display_thumbnail => true,
      :file_version_caption => generate(:alphanumstr)
    )
  }
  let(:thumbnail_no_caption_candidate) {
    Thumbnails::ThumbnailCandidate.from_hash(
      :instance_is_representative => false,
      :digital_object_title => generate(:alphanumstr),
      :file_version_file_uri => generate(:url),
      :file_version_use_statement => 'image-thumbnail',
      :file_version_file_format_name => 'jpeg',
      :file_version_xlink_show_attribute => 'embed',
      :file_version_is_representative => false,
      :file_version_is_display_thumbnail => false,
      :file_version_caption => nil
    )
  }
  let(:something_else_candidate) {
    Thumbnails::ThumbnailCandidate.from_hash(
      :instance_is_representative => false,
      :digital_object_title => generate(:alphanumstr),
      :file_version_file_uri => generate(:url),
      :file_version_use_statement => 'video-streaming',
      :file_version_file_format_name => 'avi',
      :file_version_xlink_show_attribute => nil,
      :file_version_is_representative => false,
      :file_version_is_display_thumbnail => false,
      :file_version_caption => generate(:alphanumstr)
    )
  }
  let(:display_thumbnail_candidate) {
    Thumbnails::ThumbnailCandidate.from_hash(
      :instance_is_representative => false,
      :digital_object_title => generate(:alphanumstr),
      :file_version_file_uri => generate(:url),
      :file_version_use_statement => 'image-master',
      :file_version_file_format_name => 'jpeg',
      :file_version_xlink_show_attribute => nil,
      :file_version_is_representative => false,
      :file_version_is_display_thumbnail => true,
      :file_version_caption => generate(:alphanumstr)
    )
  }
  let(:representative_candidate) {
    Thumbnails::ThumbnailCandidate.from_hash(
      :instance_is_representative => true,
      :digital_object_title => generate(:alphanumstr),
      :file_version_file_uri => generate(:url),
      :file_version_use_statement => 'image-master',
      :file_version_file_format_name => 'jpeg',
      :file_version_xlink_show_attribute => nil,
      :file_version_is_representative => true,
      :file_version_is_display_thumbnail => false,
      :file_version_caption => generate(:alphanumstr)
    )
  }
  let(:not_a_http_url_candidate) {
    Thumbnails::ThumbnailCandidate.from_hash(
      :instance_is_representative => true,
      :digital_object_title => generate(:alphanumstr),
      :file_version_file_uri => 'data:ABC123',
      :file_version_use_statement => 'image-master',
      :file_version_file_format_name => 'jpeg',
      :file_version_xlink_show_attribute => nil,
      :file_version_is_representative => true,
      :file_version_is_display_thumbnail => false,
      :file_version_caption => generate(:alphanumstr)
    )
  }
  let(:instance_representative_thumbnail_candidate) {
    Thumbnails::ThumbnailCandidate.from_hash(
      :instance_is_representative => true,
      :digital_object_title => generate(:alphanumstr),
      :file_version_file_uri => generate(:url),
      :file_version_use_statement => 'image-thumbnail',
      :file_version_file_format_name => 'jpeg',
      :file_version_xlink_show_attribute => 'embed',
      :file_version_is_representative => false,
      :file_version_is_display_thumbnail => false,
      :file_version_caption => generate(:alphanumstr)
    )
  }
  let(:instance_representative_master_candidate) {
    Thumbnails::ThumbnailCandidate.from_hash(
      :instance_is_representative => true,
      :digital_object_title => generate(:alphanumstr),
      :file_version_file_uri => generate(:url),
      :file_version_use_statement => 'image-master',
      :file_version_file_format_name => 'jpeg',
      :file_version_xlink_show_attribute => nil,
      :file_version_is_representative => false,
      :file_version_is_display_thumbnail => false,
      :file_version_caption => generate(:alphanumstr)
    )
  }
  let(:instance_representative_display_thumbnail_candidate) {
    Thumbnails::ThumbnailCandidate.from_hash(
      :instance_is_representative => true,
      :digital_object_title => generate(:alphanumstr),
      :file_version_file_uri => generate(:url),
      :file_version_use_statement => 'image-master',
      :file_version_file_format_name => 'jpeg',
      :file_version_xlink_show_attribute => nil,
      :file_version_is_representative => false,
      :file_version_is_display_thumbnail => true,
      :file_version_caption => generate(:alphanumstr)
    )
  }
  let(:instance_representative_something_else_candidate) {
    Thumbnails::ThumbnailCandidate.from_hash(
      :instance_is_representative => true,
      :digital_object_title => generate(:alphanumstr),
      :file_version_file_uri => generate(:url),
      :file_version_use_statement => 'video-streaming',
      :file_version_file_format_name => 'avi',
      :file_version_xlink_show_attribute => nil,
      :file_version_is_representative => false,
      :file_version_is_display_thumbnail => false,
      :file_version_caption => generate(:alphanumstr)
    )
  }
  let(:instance_representative_candidate) {
    Thumbnails::ThumbnailCandidate.from_hash(
      :instance_is_representative => true,
      :digital_object_title => generate(:alphanumstr),
      :file_version_file_uri => generate(:url),
      :file_version_use_statement => 'image-master',
      :file_version_file_format_name => 'jpeg',
      :file_version_xlink_show_attribute => nil,
      :file_version_is_representative => true,
      :file_version_is_display_thumbnail => false,
      :file_version_caption => generate(:alphanumstr)
    )
  }
  let(:instance_representative_no_caption_representative_candidate) {
    Thumbnails::ThumbnailCandidate.from_hash(
      :instance_is_representative => true,
      :digital_object_title => generate(:alphanumstr),
      :file_version_file_uri => generate(:url),
      :file_version_use_statement => 'image-master',
      :file_version_file_format_name => 'jpeg',
      :file_version_xlink_show_attribute => nil,
      :file_version_is_representative => true,
      :file_version_is_display_thumbnail => false,
      :file_version_caption => nil
    )
  }

  let(:not_an_embeddable) {
    Thumbnails::ThumbnailCandidate.from_hash(
      :instance_is_representative => false,
      :digital_object_title => generate(:alphanumstr),
      :file_version_file_uri => generate(:url),
      :file_version_use_statement => nil,
      :file_version_file_format_name => nil,
      :file_version_xlink_show_attribute => 'new',
      :file_version_is_representative => true,
      :file_version_is_display_thumbnail => false,
      :file_version_caption => nil,
    )
  }

  describe "calculate_image_url" do
    it "picks representative instance thumbnail candidate over others" do
      result = Resource.calculate_image_url([
                                              thumbnail_candidate,
                                              master_candidate,
                                              instance_representative_something_else_candidate,
                                              instance_representative_thumbnail_candidate,
                                              instance_representative_master_candidate,
                                            ])

      # instance_representative_thumbnail_candidate and
      # instance_representative_master_candidate are both representative, but
      # instance_representative_thumbnail_candidate has a use statement of
      # 'image-thumbnail' and wins.
      expect(result).to eq(instance_representative_thumbnail_candidate.file_version_file_uri)
    end

    it "picks representative instance display thumbnail candidate over others" do
      result = Resource.calculate_image_url([
                                              thumbnail_candidate,
                                              master_candidate,
                                              instance_representative_something_else_candidate,
                                              instance_representative_master_candidate,
                                              instance_representative_thumbnail_candidate,
                                              instance_representative_display_thumbnail_candidate,
                                            ])

      # instance_representative_display_thumbnail_candidate has `is_display_thumbnail` and wins.
      expect(result).to eq(instance_representative_display_thumbnail_candidate.file_version_file_uri)
    end

    it "picks representative instance image candidate over others" do
      result = Resource.calculate_image_url([
                                              thumbnail_candidate,
                                              master_candidate,
                                              instance_representative_something_else_candidate,
                                              instance_representative_master_candidate,
                                            ])

      # instance_representative_master_candidate is both representative and an image, so it wins.
      expect(result).to eq(instance_representative_master_candidate.file_version_file_uri)
    end

    it "handles no representative instance image candidate" do
      result = Resource.calculate_image_url([
                                              instance_representative_something_else_candidate,
                                              thumbnail_candidate,
                                            ])
      expect(result).to eq(thumbnail_candidate.file_version_file_uri)
    end

    it "picks thumbnail candidate over others" do
      result = Resource.calculate_image_url([
                                              something_else_candidate,
                                              thumbnail_candidate,
                                              master_candidate,
                                            ])
      # thumbnail_candidate has use statement of 'image-thumbnail' and wins.
      expect(result).to eq(thumbnail_candidate.file_version_file_uri)
    end

    it "picks display thumbnail candidate over others" do
      result = Resource.calculate_image_url([
                                              something_else_candidate,
                                              display_thumbnail_candidate,
                                              thumbnail_candidate,
                                              master_candidate,
                                            ])
      # display_thumbnail_candidate has `is_display_thumbnail` and wins.
      expect(result).to eq(display_thumbnail_candidate.file_version_file_uri)
    end

    it "picks display image candidate over others" do
      result = Resource.calculate_image_url([
                                              something_else_candidate,
                                              master_candidate,
                                            ])

      # master candidate wins because its file_format_name is a jpeg
      expect(result).to eq(master_candidate.file_version_file_uri)
    end

    it "ignores non http URLs" do
      result = Resource.calculate_image_url([not_a_http_url_candidate])

      expect(result).to be_nil
    end

    it "ignores non embeddable" do
      result = Resource.calculate_image_url([not_an_embeddable])

      expect(result).to be_nil
    end
  end

  describe "calculate_link_url" do
    it "picks the instance representative candidate over others" do
      result = Resource.calculate_link_url([
                                             thumbnail_candidate,
                                             master_candidate,
                                             instance_representative_thumbnail_candidate,
                                             instance_representative_master_candidate,
                                           ])

      # instance_representative_master_candidate wins over the (also
      # representative) instance_representative_thumbnail_candidate because we
      # prefer non-thumbnail use statements for links.
      expect(result).to eq(instance_representative_master_candidate.file_version_file_uri)
    end

    it "picks the instance representative representative candidate over others" do
      result = Resource.calculate_link_url([
                                             thumbnail_candidate,
                                             master_candidate,
                                             instance_representative_thumbnail_candidate,
                                             instance_representative_candidate,
                                             instance_representative_master_candidate,
                                           ])

      # instance_representative_candidate wins because it has file_version_is_representative.
      expect(result).to eq(instance_representative_candidate.file_version_file_uri)
    end

    it "picks the instance representative display thumbnail candidate over others" do
      result = Resource.calculate_link_url([
                                             thumbnail_candidate,
                                             master_candidate,
                                             instance_representative_thumbnail_candidate,
                                             instance_representative_display_thumbnail_candidate,
                                           ])

      # instance_representative_display_thumbnail_candidate beats
      # instance_representative_thumbnail_candidate because its
      # is_display_thumbnail is true.
      expect(result).to eq(instance_representative_display_thumbnail_candidate.file_version_file_uri)
    end

    it "picks any instance representative candidate over others" do
      result = Resource.calculate_link_url([
                                             thumbnail_candidate,
                                             master_candidate,
                                             instance_representative_something_else_candidate,
                                           ])

      expect(result).to eq(instance_representative_something_else_candidate.file_version_file_uri)
    end

    it "picks the first representative candidate" do
      result = Resource.calculate_link_url([
                                             thumbnail_candidate,
                                             representative_candidate,
                                             something_else_candidate,
                                             display_thumbnail_candidate,
                                           ])

      expect(result).to eq(representative_candidate.file_version_file_uri)
    end

    it "picks the display thumbnail candidate" do
      result = Resource.calculate_link_url([
                                             thumbnail_candidate,
                                             display_thumbnail_candidate,
                                           ])

      expect(result).to eq(display_thumbnail_candidate.file_version_file_uri)
    end

    it "picks the first non-thumbnail candidate" do
      result = Resource.calculate_link_url([
                                             thumbnail_candidate,
                                             something_else_candidate,
                                             display_thumbnail_candidate,
                                           ])

      expect(result).to eq(something_else_candidate.file_version_file_uri)
    end

    it "picks any candidate" do
      result = Resource.calculate_link_url([
                                             something_else_candidate,
                                           ])

      expect(result).to eq(something_else_candidate.file_version_file_uri)
    end

    it "handles it there are no candidates" do
      result = Resource.calculate_link_url([])

      expect(result).to be_nil
    end

    it "ignores non http URLs" do
      result = Resource.calculate_link_url([not_a_http_url_candidate])

      expect(result).to be_nil
    end
  end

  describe "calculate_caption" do
    it 'picks the thumbnail caption over others' do
      result = Resource.calculate_caption(build(:resource), [
        thumbnail_candidate,
        master_candidate,
        instance_representative_thumbnail_candidate,
        instance_representative_candidate,
        instance_representative_master_candidate,
      ])

      expect(result).to eq(instance_representative_thumbnail_candidate.file_version_caption)
    end

    it 'picks the instance representative representative candidate over others' do
      result = Resource.calculate_caption(build(:resource), [
        thumbnail_candidate,
        master_candidate,
        instance_representative_candidate,
        instance_representative_master_candidate,
      ])

      # instance_representative_candidate wins with file_version_is_representative.
      expect(result).to eq(instance_representative_candidate.file_version_caption)
    end

    it 'picks the instance representative thumbnail digital object title over others' do
      result = Resource.calculate_caption(build(:resource), [
        thumbnail_candidate,
        master_candidate,
        instance_representative_thumbnail_candidate,
        instance_representative_no_caption_representative_candidate,
        instance_representative_master_candidate,
      ])

      expect(result).to eq(instance_representative_thumbnail_candidate.file_version_caption)
    end

    it 'picks the instance representative thumbnail caption over others' do
      result = Resource.calculate_caption(build(:resource), [
        thumbnail_candidate,
        master_candidate,
        instance_representative_something_else_candidate,
        instance_representative_thumbnail_candidate,
        instance_representative_master_candidate,
      ])

      expect(result).to eq(instance_representative_thumbnail_candidate.file_version_caption)
    end

    it 'picks the representative caption over others' do
      result = Resource.calculate_caption(build(:resource), [
        thumbnail_candidate,
        master_candidate,
        representative_candidate,
      ])

      expect(result).to eq(representative_candidate.file_version_caption)
    end

    it 'picks the thumbnail caption over others' do
      result = Resource.calculate_caption(build(:resource), [
        something_else_candidate,
        something_else_candidate,
        thumbnail_candidate,
        master_candidate,
      ])

      expect(result).to eq(thumbnail_candidate.file_version_caption)
    end

    it 'picks the thumbnail digital object title over others' do
      result = Resource.calculate_caption(build(:resource), [
        something_else_candidate,
        something_else_candidate,
        thumbnail_no_caption_candidate,
        master_candidate,
      ])

      expect(result).to eq(thumbnail_no_caption_candidate.digital_object_title)
    end
  end
end
