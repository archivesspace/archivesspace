require 'spec_helper'

require_relative '../../common/iiif'

describe "IIIF" do

  def stub_iiif_viewer_url(value)
    allow(AppConfig).to receive(:has_key?).with(:iiif_viewer_url).and_return(true)
    allow(AppConfig).to receive(:[]).with(:iiif_viewer_url).and_return(value)
  end

  describe ".viewer_url" do

    it "appends the escaped manifest URI when the configured viewer URL is a String" do
      stub_iiif_viewer_url(:default => 'http://iiif-viewer.com?manifest=')

      url = IIIF.viewer_url('anyrepo', 'http://example.com/manifests/foo bar.json')

      expect(url).to eq('http://iiif-viewer.com?manifest=http%3A%2F%2Fexample.com%2Fmanifests%2Ffoo+bar.json')
    end

    it "calls the configured Proc with the manifest URI when the viewer URL is a Proc" do
      stub_iiif_viewer_url(
        :default => proc { |manifest_uri| "http://iiif-viewer.com/?m=#{CGI::escape(manifest_uri)}&other_param=value" }
      )

      url = IIIF.viewer_url('anyrepo', 'http://example.com/manifests/foo.json')

      expect(url).to eq('http://iiif-viewer.com/?m=http%3A%2F%2Fexample.com%2Fmanifests%2Ffoo.json&other_param=value')
    end

    it "uses a repository specific viewer URL when one is configured for the current repo_code" do
      stub_iiif_viewer_url(
        :default => 'http://default-viewer.com?manifest=',
        'myrepo' => 'http://myrepo-viewer.com?manifest='
      )

      url = IIIF.viewer_url('myrepo', 'http://example.com/manifests/foo.json')

      expect(url).to eq('http://myrepo-viewer.com?manifest=http%3A%2F%2Fexample.com%2Fmanifests%2Ffoo.json')
    end

    it "falls back to the default viewer URL when the current repo_code is not configured" do
      stub_iiif_viewer_url(
        :default => 'http://default-viewer.com?manifest=',
        'myrepo' => 'http://myrepo-viewer.com?manifest='
      )

      url = IIIF.viewer_url('otherrepo', 'http://example.com/manifests/foo.json')

      expect(url).to eq('http://default-viewer.com?manifest=http%3A%2F%2Fexample.com%2Fmanifests%2Ffoo.json')
    end

    it "raises when the configured viewer URL is neither a String nor a Proc" do
      stub_iiif_viewer_url(:default => 12345)

      expect {
        IIIF.viewer_url('anyrepo', 'http://example.com/manifests/foo.json')
      }.to raise_error('IIIF viewer URL configuration must be a String or a Proc')
    end
  end

  describe ".enabled?" do

    it "returns true when iiif_viewer_url is a Hash with a :default key" do
      stub_iiif_viewer_url(:default => 'http://iiif-viewer.com?manifest=')

      expect(IIIF.enabled?).to be(true)
    end

    it "returns false when iiif_viewer_url is not configured" do
      allow(AppConfig).to receive(:has_key?).with(:iiif_viewer_url).and_return(false)

      expect(IIIF.enabled?).to be(false)
    end

    it "returns false when iiif_viewer_url is not a Hash" do
      stub_iiif_viewer_url('http://iiif-viewer.com?manifest=')

      expect(IIIF.enabled?).to be(false)
    end

    it "returns false when iiif_viewer_url is a Hash without a :default key" do
      stub_iiif_viewer_url('myrepo' => 'http://myrepo-viewer.com?manifest=')

      expect(IIIF.enabled?).to be(false)
    end
  end

  describe ".manifest?" do

    let(:iiif_file_version) {
      {
        'file_format_name' => 'iiif',
        'use_statement' => 'text-json',
        'xlink_show_attribute' => 'embed'
      }
    }

    it "returns true when file_format_name, use_statement and xlink_show_attribute all match the IIIF values" do
      expect(IIIF.manifest?(iiif_file_version)).to be(true)
    end

    it "returns false when the file_format_name is not 'iiif'" do
      expect(IIIF.manifest?(iiif_file_version.merge('file_format_name' => 'jpeg'))).to be(false)
    end

    it "returns false when the use_statement is not 'text-json'" do
      expect(IIIF.manifest?(iiif_file_version.merge('use_statement' => 'image-master'))).to be(false)
    end

    it "returns false when the xlink_show_attribute is not 'embed'" do
      expect(IIIF.manifest?(iiif_file_version.merge('xlink_show_attribute' => 'new'))).to be(false)
    end

    it "returns false when an indicative field is missing" do
      expect(IIIF.manifest?(iiif_file_version.reject { |k, _| k == 'file_format_name' })).to be(false)
    end
  end
end
