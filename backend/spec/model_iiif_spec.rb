require 'spec_helper'

require_relative '../../common/iiif'

describe "IIIF" do

  def stub_iiif_viewer(value)
    allow(AppConfig).to receive(:has_key?).with(:iiif_viewer).and_return(true)
    allow(AppConfig).to receive(:[]).with(:iiif_viewer).and_return(value)
  end

  def stub_iiif_viewer_unset
    allow(AppConfig).to receive(:has_key?).with(:iiif_viewer).and_return(false)
  end

  describe ".viewer_url" do

    context "when a URL String is configured" do
      before { stub_iiif_viewer('http://iiif-viewer.com?manifest=') }

      it "appends the escaped manifest URI to the viewer URL" do
        url = IIIF.viewer_url('anyrepo', 'http://example.com/manifests/foo bar.json')

        expect(url).to eq('http://iiif-viewer.com?manifest=http%3A%2F%2Fexample.com%2Fmanifests%2Ffoo+bar.json')
      end
    end

    context "when a Proc is configured" do
      before do
        stub_iiif_viewer(proc { |manifest_uri| "http://iiif-viewer.com/?m=#{CGI::escape(manifest_uri)}&other_param=value" })
      end

      it "calls the Proc with the manifest URI" do
        url = IIIF.viewer_url('anyrepo', 'http://example.com/manifests/foo.json')

        expect(url).to eq('http://iiif-viewer.com/?m=http%3A%2F%2Fexample.com%2Fmanifests%2Ffoo.json&other_param=value')
      end
    end

    context "when the bundled Universal Viewer is configured" do
      before { stub_iiif_viewer('universal_viewer') }

      it "builds the bundled Universal Viewer URL" do
        url = IIIF.viewer_url('anyrepo', 'http://example.com/manifests/foo bar.json', '/staff/')

        expect(url).to eq('/staff/uv/uv.html#?manifest=http%3A%2F%2Fexample.com%2Fmanifests%2Ffoo+bar.json')
      end
    end

    context "when the bundled Mirador viewer is configured" do
      before { stub_iiif_viewer('mirador') }

      it "builds the bundled Mirador URL" do
        url = IIIF.viewer_url('anyrepo', 'http://example.com/manifests/foo bar.json', '/staff/')

        expect(url).to eq('/staff/mirador/index.html?manifest=http%3A%2F%2Fexample.com%2Fmanifests%2Ffoo+bar.json')
      end
    end

    context "when a Hash keyed on repo_code is configured" do
      before do
        stub_iiif_viewer(
          {
            :default => 'universal_viewer',
            'mirador_repo' => 'mirador',
            'external_repo' => 'http://myrepo-viewer.com?manifest='
          }
        )
      end

      it "uses the bundled viewer selected for that repo_code" do
        url = IIIF.viewer_url('mirador_repo', 'http://example.com/manifests/foo.json', '/staff/')

        expect(url).to eq('/staff/mirador/index.html?manifest=http%3A%2F%2Fexample.com%2Fmanifests%2Ffoo.json')
      end

      it "uses the external viewer URL selected for that repo_code" do
        url = IIIF.viewer_url('external_repo', 'http://example.com/manifests/foo.json', '/staff/')

        expect(url).to eq('http://myrepo-viewer.com?manifest=http%3A%2F%2Fexample.com%2Fmanifests%2Ffoo.json')
      end

      it "falls back to the :default for other repo_codes" do
        url = IIIF.viewer_url('otherrepo', 'http://example.com/manifests/foo.json', '/staff/')

        expect(url).to eq('/staff/uv/uv.html#?manifest=http%3A%2F%2Fexample.com%2Fmanifests%2Ffoo.json')
      end
    end

    context "when the viewer is configured as 'none'" do
      before { stub_iiif_viewer('none') }

      it "raises" do
        expect {
          IIIF.viewer_url('anyrepo', 'http://example.com/manifests/foo.json', '/staff/')
        }.to raise_error('IIIF viewer URL configuration must be a String or a Proc')
      end
    end

    context "when no viewer is configured" do
      before { stub_iiif_viewer_unset }

      it "raises" do
        expect {
          IIIF.viewer_url('anyrepo', 'http://example.com/manifests/foo.json', '/staff/')
        }.to raise_error('IIIF viewer URL configuration must be a String or a Proc')
      end
    end

    context "when a Hash has no entry for the repo and no :default" do
      before { stub_iiif_viewer({ 'myrepo' => 'mirador' }) }

      it "raises for other repo_codes" do
        expect {
          IIIF.viewer_url('otherrepo', 'http://example.com/manifests/foo.json', '/staff/')
        }.to raise_error('IIIF viewer URL configuration must be a String or a Proc')
      end
    end
  end

  describe ".enabled?" do

    context "when a bundled viewer is configured" do
      before { stub_iiif_viewer('universal_viewer') }

      it "returns true" do
        expect(IIIF.enabled?).to be(true)
      end
    end

    context "when a URL String is configured" do
      before { stub_iiif_viewer('http://iiif-viewer.com?manifest=') }

      it "returns true" do
        expect(IIIF.enabled?).to be(true)
      end
    end

    context "when a Proc is configured" do
      before { stub_iiif_viewer(proc { |manifest_uri| manifest_uri }) }

      it "returns true" do
        expect(IIIF.enabled?).to be(true)
      end
    end

    context "when the viewer is configured as 'none'" do
      before { stub_iiif_viewer('none') }

      it "returns false" do
        expect(IIIF.enabled?).to be(false)
      end
    end

    context "when no viewer is configured" do
      before { stub_iiif_viewer_unset }

      it "returns false" do
        expect(IIIF.enabled?).to be(false)
      end
    end

    context "when a Hash with a :default is configured" do
      before { stub_iiif_viewer({ :default => 'universal_viewer' }) }

      it "returns true" do
        expect(IIIF.enabled?).to be(true)
      end
    end

    context "when a Hash without a matching entry or :default is configured" do
      before { stub_iiif_viewer({ 'myrepo' => 'mirador' }) }

      it "returns true for the configured repo_code" do
        expect(IIIF.enabled?('myrepo')).to be(true)
      end

      it "returns false for other repo_codes" do
        expect(IIIF.enabled?('otherrepo')).to be(false)
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
