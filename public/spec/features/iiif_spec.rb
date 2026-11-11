require 'spec_helper'
require 'rails_helper'

describe "IIIF integration" do

  before(:all) do
    @manifest_url = 'https://iiif.io/api/cookbook/recipe/0009-book-1/manifest.json'

    @do = create(:digital_object,
                 publish: true,
                 file_versions: [
                   build(:file_version,
                         file_format_name: 'iiif',
                         use_statement: 'text-json',
                         xlink_show_attribute: 'embed',
                         file_uri: @manifest_url,
                         publish: true),
                   build(:file_version,
                         file_format_name: 'jpeg',
                         publish: true),
                   build(:file_version,
                         file_format_name: 'avi',
                         publish: false),
                 ])

    @resource = create(:resource,
                       title: 'IIIF test resource',
                       publish: true,
                       instances: [build(:instance_digital,
                                         digital_object: { ref: @do.uri },
                                         is_representative: true
                                   )]
    )

    @resource_without_iiif = create(:resource,
                       title: 'IIIF test resource without a manifest',
                       publish: true
    )

    @accession = create(:accession,
                        title: 'IIIF test accession',
                        publish: true,
                        instances: [build(:instance_digital,
                                          digital_object: { ref: @do.uri },
                                          is_representative: true
                                    )]
    )

    @ao = create(:archival_object,
                 publish: true,
                 title: 'IIIF test archival object',
                 resource: {'ref' => @resource.uri},
                 instances: [build(:instance_digital,
                                   digital_object: { ref: @do.uri },
                                   is_representative: true
                             )]
    )

    @unpublished_do = create(:digital_object,
                             publish: false,
                             file_versions: [
                               build(:file_version,
                                     file_format_name: 'iiif',
                                     use_statement: 'text-json',
                                     xlink_show_attribute: 'embed',
                                     file_uri: @manifest_url,
                                     publish: true)
                             ])

    @resource_non_representative = create(:resource,
                                          title: 'IIIF test resource with a non-representative manifest',
                                          publish: true,
                                          instances: [build(:instance_digital,
                                                            digital_object: { ref: @do.uri },
                                                            is_representative: false)])

    @ao_non_representative = create(:archival_object,
                                    publish: true,
                                    title: 'IIIF test archival object with a non-representative manifest',
                                    resource: {'ref' => @resource.uri},
                                    instances: [build(:instance_digital,
                                                      digital_object: { ref: @do.uri },
                                                      is_representative: false)])

    @accession_non_representative = create(:accession,
                                           title: 'IIIF test accession with a non-representative manifest',
                                           publish: true,
                                           instances: [build(:instance_digital,
                                                             digital_object: { ref: @do.uri },
                                                             is_representative: false)])

    unpublished_representative_instances = -> {
      [build(:instance_digital, digital_object: { ref: @unpublished_do.uri }, is_representative: true),
       build(:instance_digital, digital_object: { ref: @do.uri }, is_representative: false)]
    }

    @resource_unpublished_representative = create(:resource,
                                                  title: 'IIIF test resource with an unpublished representative manifest',
                                                  publish: true,
                                                  instances: unpublished_representative_instances.call)

    @ao_unpublished_representative = create(:archival_object,
                                            publish: true,
                                            title: 'IIIF test archival object with an unpublished representative manifest',
                                            resource: {'ref' => @resource.uri},
                                            instances: unpublished_representative_instances.call)

    @accession_unpublished_representative = create(:accession,
                                                   title: 'IIIF test accession with an unpublished representative manifest',
                                                   publish: true,
                                                   instances: unpublished_representative_instances.call)

    suppressed_do = create(:digital_object,
                           publish: true,
                           file_versions: [
                             build(:file_version,
                                   file_format_name: 'iiif',
                                   use_statement: 'text-json',
                                   xlink_show_attribute: 'embed',
                                   file_uri: @manifest_url,
                                   publish: true)
                           ])

    @resource_suppressed_representative = create(:resource,
                                                 title: 'IIIF test resource with a suppressed representative manifest',
                                                 publish: true,
                                                 instances: [build(:instance_digital,
                                                                   digital_object: { ref: suppressed_do.uri },
                                                                   is_representative: true)])

    @ao_suppressed_representative = create(:archival_object,
                                           publish: true,
                                           title: 'IIIF test archival object with a suppressed representative manifest',
                                           resource: {'ref' => @resource.uri},
                                           instances: [build(:instance_digital,
                                                             digital_object: { ref: suppressed_do.uri },
                                                             is_representative: true)])

    @accession_suppressed_representative = create(:accession,
                                                  title: 'IIIF test accession with a suppressed representative manifest',
                                                  publish: true,
                                                  instances: [build(:instance_digital,
                                                                    digital_object: { ref: suppressed_do.uri },
                                                                    is_representative: true)])

    suppressed_do.set_suppressed(true)

    run_indexers
  end

  describe "when enabled" do

    before(:each) do
      @viewer_url = 'http://example.org/iiif-test?manifest='

      allow(AppConfig).to receive(:[]).and_call_original
      allow(AppConfig).to receive(:has_key?).and_call_original
      allow(AppConfig).to receive(:has_key?).with(:iiif_viewer)
                                            .and_return(true)
      allow(AppConfig).to receive(:[]).with(:iiif_viewer)
                                      .and_return(@viewer_url)
    end

    describe "the model" do
      it "knows we're IIIF enabled" do
        expect(IIIF.enabled?).to eq(true)
      end

      it "finds the resource IIIF manifest" do
        record = ArchivesSpaceClient.instance.get_record(@resource.uri)
        expect(record.iiif_manifest).to_not be_nil
        expect(record.iiif_manifest.fetch('file_uri')).to eq(@manifest_url)
      end

      it "finds the archival object IIIF manifest" do
        record = ArchivesSpaceClient.instance.get_record(@ao.uri)
        expect(record.iiif_manifest).to_not be_nil
        expect(record.iiif_manifest.fetch('file_uri')).to eq(@manifest_url)
      end

      it "finds the accession IIIF manifest" do
        record = ArchivesSpaceClient.instance.get_record(@accession.uri)
        expect(record.iiif_manifest).to_not be_nil
        expect(record.iiif_manifest.fetch('file_uri')).to eq(@manifest_url)
      end

      it "finds the digital object IIIF manifest" do
        record = ArchivesSpaceClient.instance.get_record(@do.uri)
        expect(record.iiif_manifest).to_not be_nil
        expect(record.iiif_manifest.fetch('file_uri')).to eq(@manifest_url)
      end

      it "ignores a IIIF manifest on a non-representative resource instance" do
        expect(ArchivesSpaceClient.instance.get_record(@resource_non_representative.uri).iiif_manifest).to be_nil
      end

      it "ignores a IIIF manifest on a non-representative archival object instance" do
        expect(ArchivesSpaceClient.instance.get_record(@ao_non_representative.uri).iiif_manifest).to be_nil
      end

      it "ignores a IIIF manifest on a non-representative accession instance" do
        expect(ArchivesSpaceClient.instance.get_record(@accession_non_representative.uri).iiif_manifest).to be_nil
      end

      it "ignores the resource IIIF manifests when its representative digital object is unpublished" do
        expect(ArchivesSpaceClient.instance.get_record(@resource_unpublished_representative.uri).iiif_manifest).to be_nil
      end

      it "ignores the archival object IIIF manifests when its representative digital object is unpublished" do
        expect(ArchivesSpaceClient.instance.get_record(@ao_unpublished_representative.uri).iiif_manifest).to be_nil
      end

      it "ignores the accession IIIF manifests when its representative digital object is unpublished" do
        expect(ArchivesSpaceClient.instance.get_record(@accession_unpublished_representative.uri).iiif_manifest).to be_nil
      end

      it "ignores the resource IIIF manifest when its representative digital object is suppressed" do
        expect(ArchivesSpaceClient.instance.get_record(@resource_suppressed_representative.uri).iiif_manifest).to be_nil
      end

      it "ignores the archival object IIIF manifest when its representative digital object is suppressed" do
        expect(ArchivesSpaceClient.instance.get_record(@ao_suppressed_representative.uri).iiif_manifest).to be_nil
      end

      it "ignores the accession IIIF manifest when its representative digital object is suppressed" do
        expect(ArchivesSpaceClient.instance.get_record(@accession_suppressed_representative.uri).iiif_manifest).to be_nil
      end
    end


    describe "the UI" do
      it "renders the iframe when the resource has an IIIF manifest" do
        visit @resource.uri

        expect(page).to have_css('.iiif-embed')
        expect(page).to have_css('.iiif-embed iframe')

        iiif_iframe = find('.iiif-embed iframe')
        expect(CGI.unescape(iiif_iframe['src'])).to eq(@viewer_url + @manifest_url)
        expect(iiif_iframe['allow']).to eq('fullscreen')
      end

      it "renders the iframe when the archival object has an IIIF manifest" do
        visit @ao.uri

        expect(page).to have_css('.iiif-embed')
        expect(page).to have_css('.iiif-embed iframe')

        iiif_iframe = find('.iiif-embed iframe')
        expect(CGI.unescape(iiif_iframe['src'])).to eq(@viewer_url + @manifest_url)
        expect(iiif_iframe['allow']).to eq('fullscreen')
      end

      it "renders the iframe when the accession has an IIIF manifest" do
        visit @accession.uri

        expect(page).to have_css('.iiif-embed')
        expect(page).to have_css('.iiif-embed iframe')

        iiif_iframe = find('.iiif-embed iframe')
        expect(CGI.unescape(iiif_iframe['src'])).to eq(@viewer_url + @manifest_url)
        expect(iiif_iframe['allow']).to eq('fullscreen')
      end

      it "renders the iframe when the digital object has an IIIF manifest" do
        visit @do.uri

        expect(page).to have_css('.iiif-embed')
        expect(page).to have_css('.iiif-embed iframe')

        iiif_iframe = find('.iiif-embed iframe')
        expect(CGI.unescape(iiif_iframe['src'])).to eq(@viewer_url + @manifest_url)
        expect(iiif_iframe['allow']).to eq('fullscreen')
      end

      it "doesn't render an iframe when there is no IIIF manifest" do
        visit @resource_without_iiif.uri

        expect(page).to_not have_css('.iiif-embed')
      end

      it "doesn't render an iframe for a IIIF manifest on a non-representative resource instance" do
        visit @resource_non_representative.uri

        expect(page).to have_css('h1', text: 'IIIF test resource with a non-representative manifest')
        expect(page).to_not have_css('.iiif-embed')
      end

      it "doesn't render an iframe for a IIIF manifest on a non-representative archival object instance" do
        visit @ao_non_representative.uri

        expect(page).to have_css('h1', text: 'IIIF test archival object with a non-representative manifest')
        expect(page).to_not have_css('.iiif-embed')
      end

      it "doesn't render an iframe for a IIIF manifest on a non-representative accession instance" do
        visit @accession_non_representative.uri

        expect(page).to have_css('h1', text: 'IIIF test accession with a non-representative manifest')
        expect(page).to_not have_css('.iiif-embed')
      end

      it "doesn't render an iframe when the resource's representative digital object is unpublished" do
        visit @resource_unpublished_representative.uri

        expect(page).to have_css('h1', text: 'IIIF test resource with an unpublished representative manifest')
        expect(page).to_not have_css('.iiif-embed')
      end

      it "doesn't render an iframe when the archival object's representative digital object is unpublished" do
        visit @ao_unpublished_representative.uri

        expect(page).to have_css('h1', text: 'IIIF test archival object with an unpublished representative manifest')
        expect(page).to_not have_css('.iiif-embed')
      end

      it "doesn't render an iframe when the accession's representative digital object is unpublished" do
        visit @accession_unpublished_representative.uri

        expect(page).to have_css('h1', text: 'IIIF test accession with an unpublished representative manifest')
        expect(page).to_not have_css('.iiif-embed')
      end

      it "doesn't render an iframe when the resource's representative digital object is suppressed" do
        visit @resource_suppressed_representative.uri

        expect(page).to have_css('h1', text: 'IIIF test resource with a suppressed representative manifest')
        expect(page).to_not have_css('.iiif-embed')
      end

      it "doesn't render an iframe when the archival object's representative digital object is suppressed" do
        visit @ao_suppressed_representative.uri

        expect(page).to have_css('h1', text: 'IIIF test archival object with a suppressed representative manifest')
        expect(page).to_not have_css('.iiif-embed')
      end

      it "doesn't render an iframe when the accession's representative digital object is suppressed" do
        visit @accession_suppressed_representative.uri

        expect(page).to have_css('h1', text: 'IIIF test accession with a suppressed representative manifest')
        expect(page).to_not have_css('.iiif-embed')
      end
    end
  end

  describe "when using the bundled Universal Viewer" do
    before(:each) do
      allow(AppConfig).to receive(:[]).and_call_original
      allow(AppConfig).to receive(:has_key?).and_call_original
      allow(AppConfig).to receive(:has_key?).with(:iiif_viewer)
                                            .and_return(true)
      allow(AppConfig).to receive(:[]).with(:iiif_viewer)
                                      .and_return('universal_viewer')
    end

    it "knows we're IIIF enabled" do
      expect(IIIF.enabled?).to be(true)
    end

    it "embeds the bundled Universal Viewer and renders the manifest" do
      visit @resource.uri

      expect(page).to have_css('.iiif-embed iframe')
      iiif_iframe = find('.iiif-embed iframe')
      expect(iiif_iframe['src']).to end_with("/uv/uv.html#?manifest=#{CGI.escape(@manifest_url)}")
      expect(iiif_iframe['allow']).to eq('fullscreen')

      within_frame(iiif_iframe) do
        expect(page).to have_content('Simple Manifest - Book', wait: 30)
      end
    end
  end

  describe "when using the bundled Mirador viewer" do
    before(:each) do
      allow(AppConfig).to receive(:[]).and_call_original
      allow(AppConfig).to receive(:has_key?).and_call_original
      allow(AppConfig).to receive(:has_key?).with(:iiif_viewer)
                                            .and_return(true)
      allow(AppConfig).to receive(:[]).with(:iiif_viewer)
                                      .and_return('mirador')
    end

    it "knows we're IIIF enabled" do
      expect(IIIF.enabled?).to be(true)
    end

    it "embeds the bundled Mirador viewer and renders the manifest" do
      visit @resource.uri

      expect(page).to have_css('.iiif-embed iframe')
      iiif_iframe = find('.iiif-embed iframe')
      expect(iiif_iframe['src']).to end_with("/mirador/index.html?manifest=#{CGI.escape(@manifest_url)}")
      expect(iiif_iframe['allow']).to eq('fullscreen')

      within_frame(iiif_iframe) do
        expect(page).to have_content('Simple Manifest - Book', wait: 30)
      end
    end
  end

  describe "when disabled" do
    before(:each) do
      allow(AppConfig).to receive(:[]).and_call_original
      allow(AppConfig).to receive(:has_key?).and_call_original
      allow(AppConfig).to receive(:has_key?).with(:iiif_viewer)
                                            .and_return(true)
      allow(AppConfig).to receive(:[]).with(:iiif_viewer)
                                      .and_return('none')
    end

    it "knows it is disabled" do
      expect(IIIF.enabled?).to be(false)
    end

    it "doesn't render an iframe" do
      visit @resource.uri

      expect(page).to_not have_css('.iiif-embed')
    end
  end

  describe "a manifest is never displayed as a thumbnail image" do
    before(:all) do
      @image_url = 'http://example.com/a-real-image.jpg'

      @manifest_only = create(:digital_object,
                              publish: true,
                              title: 'IIIF manifest only digital object',
                              file_versions: [
                                build(:file_version,
                                      file_format_name: 'iiif',
                                      use_statement: 'text-json',
                                      xlink_show_attribute: 'embed',
                                      file_uri: @manifest_url,
                                      publish: true)
                              ])

      @manifest_and_image = create(:digital_object,
                                   publish: true,
                                   title: 'IIIF manifest and image digital object',
                                   file_versions: [
                                     build(:file_version,
                                           file_format_name: 'iiif',
                                           use_statement: 'text-json',
                                           xlink_show_attribute: 'embed',
                                           file_uri: @manifest_url,
                                           publish: true),
                                     build(:file_version,
                                           file_format_name: 'jpeg',
                                           use_statement: 'image-service',
                                           xlink_show_attribute: 'embed',
                                           file_uri: @image_url,
                                           is_display_thumbnail: true,
                                           publish: true)
                                   ])

      @resource_with_manifest_only = create(:resource,
                                            publish: true,
                                            title: 'IIIF resource whose representative instance is a manifest only digital object',
                                            instances: [build(:instance_digital,
                                                              digital_object: { ref: @manifest_only.uri },
                                                              is_representative: true)])

      run_indexers
    end

    before(:each) do
      allow(AppConfig).to receive(:[]).and_call_original
      allow(AppConfig).to receive(:has_key?).and_call_original
      allow(AppConfig).to receive(:has_key?).with(:iiif_viewer)
                                            .and_return(true)
      allow(AppConfig).to receive(:[]).with(:iiif_viewer)
                                      .and_return('universal_viewer')
    end

    context "when a digital object's only file version is a manifest" do
      before(:each) do
        visit @manifest_only.uri
      end

      it "shows no image" do
        expect(page).to_not have_css("img[src='#{@manifest_url}']", visible: :all)
        expect(page).to_not have_css('.objectimage')
        expect(page).to_not have_css('.pui-thumbnail', visible: :all)
      end

      it "still embeds the viewer" do
        expect(page).to have_css('.iiif-embed iframe')
      end
    end

    context "when a digital object has both a manifest and an image" do
      before(:each) do
        visit @manifest_and_image.uri
      end

      it "shows the image rather than the manifest" do
        expect(page).to_not have_css("img[src='#{@manifest_url}']", visible: :all)
        expect(page).to have_css("img[src='#{@image_url}']", visible: :all)
      end
    end

    context "when a record's representative digital object has only a manifest" do
      before(:each) do
        visit @resource_with_manifest_only.uri
      end

      it "shows no image" do
        expect(page).to_not have_css("img[src='#{@manifest_url}']", visible: :all)
        expect(page).to_not have_css('.objectimage')
        expect(page).to_not have_css('.pui-thumbnail', visible: :all)
      end
    end
  end
end
