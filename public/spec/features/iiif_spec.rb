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

    @ao = create(:archival_object,
                 publish: true,
                 title: 'IIIF test archival object',
                 resource: {'ref' => @resource.uri},
                 instances: [build(:instance_digital,
                                   digital_object: { ref: @do.uri },
                                   is_representative: true
                             )]
    )

    run_indexers
  end

  describe "when enabled" do

    before(:each) do
      @viewer_url = 'http://example.org/iiif-test?manifest='

      allow(AppConfig).to receive(:[]).and_call_original
      allow(AppConfig).to receive(:has_key?).and_call_original
      allow(AppConfig).to receive(:has_key?).with(:iiif_viewer_url)
                                            .and_return(true)
      allow(AppConfig).to receive(:[]).with(:iiif_viewer_url)
                                      .and_return({ :default => @viewer_url })
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

      it "finds the digital object IIIF manifest" do
        record = ArchivesSpaceClient.instance.get_record(@do.uri)
        expect(record.iiif_manifest).to_not be_nil
        expect(record.iiif_manifest.fetch('file_uri')).to eq(@manifest_url)
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
    end
  end

  describe "when using the bundled viewer" do
    before(:each) do
      allow(AppConfig).to receive(:[]).and_call_original
      allow(AppConfig).to receive(:has_key?).and_call_original
      allow(AppConfig).to receive(:has_key?).with(:iiif_viewer_url)
                                            .and_return(false)
      allow(AppConfig).to receive(:has_key?).with(:iiif_use_bundled_viewer)
                                            .and_return(true)
      allow(AppConfig).to receive(:[]).with(:iiif_use_bundled_viewer)
                                      .and_return(true)
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

  describe "when disabled" do
    before(:each) do
      allow(AppConfig).to receive(:[]).and_call_original
      allow(AppConfig).to receive(:has_key?).and_call_original
      allow(AppConfig).to receive(:[]).with(:iiif_viewer_url)
                                      .and_return(nil)
      allow(AppConfig).to receive(:has_key?).with(:iiif_viewer_url)
                                            .and_return(false)
      allow(AppConfig).to receive(:has_key?).with(:iiif_use_bundled_viewer)
                                            .and_return(true)
      allow(AppConfig).to receive(:[]).with(:iiif_use_bundled_viewer)
                                      .and_return(false)
    end

    it "knows it is disabled" do
      expect(IIIF.enabled?).to be(false)
    end

    it "doesn't render an iframe" do
      visit @resource.uri

      expect(page).to_not have_css('.iiif-embed')
    end
  end
end
