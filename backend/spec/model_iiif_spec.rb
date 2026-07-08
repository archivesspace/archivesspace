require 'spec_helper'

require_relative '../../common/iiif'

describe "IIIF" do

  describe ".viewer_url" do

    context "when a String viewer URL is configured" do
      before do
        allow(AppConfig).to receive(:has_key?).with(:iiif_viewer_url).and_return(true)
        allow(AppConfig).to receive(:[]).with(:iiif_viewer_url)
                                        .and_return({ :default => 'http://iiif-viewer.com?manifest=' })
        allow(AppConfig).to receive(:has_key?).with(:iiif_use_bundled_viewer).and_return(false)
      end

      it "appends the escaped manifest URI to the viewer URL" do
        url = IIIF.viewer_url('anyrepo', 'http://example.com/manifests/foo bar.json')

        expect(url).to eq('http://iiif-viewer.com?manifest=http%3A%2F%2Fexample.com%2Fmanifests%2Ffoo+bar.json')
      end
    end

    context "when a Proc viewer URL is configured" do
      before do
        allow(AppConfig).to receive(:has_key?).with(:iiif_viewer_url).and_return(true)
        allow(AppConfig).to receive(:[]).with(:iiif_viewer_url).and_return(
          { :default => proc { |manifest_uri| "http://iiif-viewer.com/?m=#{CGI::escape(manifest_uri)}&other_param=value" } }
        )
        allow(AppConfig).to receive(:has_key?).with(:iiif_use_bundled_viewer).and_return(false)
      end

      it "calls the Proc with the manifest URI" do
        url = IIIF.viewer_url('anyrepo', 'http://example.com/manifests/foo.json')

        expect(url).to eq('http://iiif-viewer.com/?m=http%3A%2F%2Fexample.com%2Fmanifests%2Ffoo.json&other_param=value')
      end
    end

    context "when a repository specific viewer URL is configured" do
      before do
        allow(AppConfig).to receive(:has_key?).with(:iiif_viewer_url).and_return(true)
        allow(AppConfig).to receive(:[]).with(:iiif_viewer_url).and_return(
          {
            :default => 'http://default-viewer.com?manifest=',
            'myrepo' => 'http://myrepo-viewer.com?manifest='
          }
        )
        allow(AppConfig).to receive(:has_key?).with(:iiif_use_bundled_viewer).and_return(false)
      end

      it "uses the repository specific viewer URL for that repo_code" do
        url = IIIF.viewer_url('myrepo', 'http://example.com/manifests/foo.json')

        expect(url).to eq('http://myrepo-viewer.com?manifest=http%3A%2F%2Fexample.com%2Fmanifests%2Ffoo.json')
      end

      it "falls back to the default viewer URL for other repo_codes" do
        url = IIIF.viewer_url('otherrepo', 'http://example.com/manifests/foo.json')

        expect(url).to eq('http://default-viewer.com?manifest=http%3A%2F%2Fexample.com%2Fmanifests%2Ffoo.json')
      end
    end

    context "when the configured viewer URL is neither a String nor a Proc" do
      before do
        allow(AppConfig).to receive(:has_key?).with(:iiif_viewer_url).and_return(true)
        allow(AppConfig).to receive(:[]).with(:iiif_viewer_url).and_return({ :default => 12345 })
        allow(AppConfig).to receive(:has_key?).with(:iiif_use_bundled_viewer).and_return(false)
      end

      it "raises" do
        expect {
          IIIF.viewer_url('anyrepo', 'http://example.com/manifests/foo.json')
        }.to raise_error('IIIF viewer URL configuration must be a String or a Proc')
      end
    end

    context "when no external viewer is configured but the bundled viewer is enabled" do
      before do
        allow(AppConfig).to receive(:has_key?).with(:iiif_viewer_url).and_return(false)
        allow(AppConfig).to receive(:has_key?).with(:iiif_use_bundled_viewer).and_return(true)
        allow(AppConfig).to receive(:[]).with(:iiif_use_bundled_viewer).and_return(true)
      end

      it "falls back to the bundled Universal Viewer" do
        url = IIIF.viewer_url('anyrepo', 'http://example.com/manifests/foo bar.json', '/staff/')

        expect(url).to eq('/staff/uv/uv.html#?manifest=http%3A%2F%2Fexample.com%2Fmanifests%2Ffoo+bar.json')
      end
    end

    context "when both an external viewer and the bundled viewer are configured" do
      before do
        allow(AppConfig).to receive(:has_key?).with(:iiif_viewer_url).and_return(true)
        allow(AppConfig).to receive(:[]).with(:iiif_viewer_url)
                                        .and_return({ :default => 'http://iiif-viewer.com?manifest=' })
        allow(AppConfig).to receive(:has_key?).with(:iiif_use_bundled_viewer).and_return(true)
        allow(AppConfig).to receive(:[]).with(:iiif_use_bundled_viewer).and_return(true)
      end

      it "prefers the external viewer" do
        url = IIIF.viewer_url('anyrepo', 'http://example.com/manifests/foo.json', '/staff/')

        expect(url).to eq('http://iiif-viewer.com?manifest=http%3A%2F%2Fexample.com%2Fmanifests%2Ffoo.json')
      end
    end

    context "when neither an external viewer nor the bundled viewer is available" do
      before do
        allow(AppConfig).to receive(:has_key?).with(:iiif_viewer_url).and_return(false)
        allow(AppConfig).to receive(:has_key?).with(:iiif_use_bundled_viewer).and_return(false)
      end

      it "raises" do
        expect {
          IIIF.viewer_url('anyrepo', 'http://example.com/manifests/foo.json', '/staff/')
        }.to raise_error('IIIF viewer URL configuration must be a String or a Proc')
      end
    end
  end

  describe ".enabled?" do

    context "when iiif_viewer_url is a Hash with a :default key" do
      before do
        allow(AppConfig).to receive(:has_key?).with(:iiif_use_bundled_viewer).and_return(false)
        allow(AppConfig).to receive(:has_key?).with(:iiif_viewer_url).and_return(true)
        allow(AppConfig).to receive(:[]).with(:iiif_viewer_url)
                                        .and_return({ :default => 'http://iiif-viewer.com?manifest=' })
      end

      it "returns true" do
        expect(IIIF.enabled?).to be(true)
      end
    end

    context "when the bundled viewer is enabled" do
      before do
        allow(AppConfig).to receive(:has_key?).with(:iiif_use_bundled_viewer).and_return(true)
        allow(AppConfig).to receive(:[]).with(:iiif_use_bundled_viewer).and_return(true)
      end

      it "returns true" do
        expect(IIIF.enabled?).to be(true)
      end
    end

    context "when neither an external viewer nor the bundled viewer is configured" do
      before do
        allow(AppConfig).to receive(:has_key?).with(:iiif_use_bundled_viewer).and_return(false)
        allow(AppConfig).to receive(:has_key?).with(:iiif_viewer_url).and_return(false)
      end

      it "returns false" do
        expect(IIIF.enabled?).to be(false)
      end
    end

    context "when iiif_viewer_url is not a Hash and the bundled viewer is off" do
      before do
        allow(AppConfig).to receive(:has_key?).with(:iiif_use_bundled_viewer).and_return(false)
        allow(AppConfig).to receive(:has_key?).with(:iiif_viewer_url).and_return(true)
        allow(AppConfig).to receive(:[]).with(:iiif_viewer_url).and_return('http://iiif-viewer.com?manifest=')
      end

      it "returns false" do
        expect(IIIF.enabled?).to be(false)
      end
    end

    context "when iiif_viewer_url is a Hash without a :default key and the bundled viewer is off" do
      before do
        allow(AppConfig).to receive(:has_key?).with(:iiif_use_bundled_viewer).and_return(false)
        allow(AppConfig).to receive(:has_key?).with(:iiif_viewer_url).and_return(true)
        allow(AppConfig).to receive(:[]).with(:iiif_viewer_url)
                                        .and_return({ 'myrepo' => 'http://myrepo-viewer.com?manifest=' })
      end

      it "returns false" do
        expect(IIIF.enabled?).to be(false)
      end
    end
  end

  describe ".manifest?" do

    before do
      @file_version = {
        'file_format_name' => 'iiif',
        'use_statement' => 'text-json',
        'xlink_show_attribute' => 'embed'
      }
    end

    context "when file_format_name, use_statement and xlink_show_attribute all match the IIIF values" do
      it "returns true" do
        expect(IIIF.manifest?(@file_version)).to be(true)
      end
    end

    context "when the file_format_name is not 'iiif'" do
      before { @file_version['file_format_name'] = 'jpeg' }

      it "returns false" do
        expect(IIIF.manifest?(@file_version)).to be(false)
      end
    end

    context "when the use_statement is not 'text-json'" do
      before { @file_version['use_statement'] = 'image-master' }

      it "returns false" do
        expect(IIIF.manifest?(@file_version)).to be(false)
      end
    end

    context "when the xlink_show_attribute is not 'embed'" do
      before { @file_version['xlink_show_attribute'] = 'new' }

      it "returns false" do
        expect(IIIF.manifest?(@file_version)).to be(false)
      end
    end

    context "when an indicative field is missing" do
      before { @file_version.delete('file_format_name') }

      it "returns false" do
        expect(IIIF.manifest?(@file_version)).to be(false)
      end
    end
  end
end
