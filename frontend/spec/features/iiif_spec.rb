# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'IIIF viewer', js: true do
  before(:all) do
    @repo = create(:repo, repo_code: "iiif_test_#{Time.now.to_i}")
    set_repo(@repo)

    @manifest_url = 'https://iiif.io/api/cookbook/recipe/0009-book-1/manifest.json'
    @digital_object = create(
      :digital_object,
      title: "IIIF test digital object #{Time.now.to_i}",
      file_versions: [
        {
          publish: true,
          file_uri: @manifest_url,
          use_statement: 'text-json',
          xlink_show_attribute: 'embed',
          file_format_name: 'iiif'
        }
      ]
    )
  end

  before(:each) do
    login_admin
    select_repository(@repo)
  end

  context 'when using the bundled Universal Viewer' do
    before(:each) do
      allow(AppConfig).to receive(:[]).and_call_original
      allow(AppConfig).to receive(:has_key?).and_call_original
      allow(AppConfig).to receive(:has_key?).with(:iiif_viewer).and_return(true)
      allow(AppConfig).to receive(:[]).with(:iiif_viewer).and_return('universal_viewer')
    end

    it 'embeds the bundled Universal Viewer and renders the manifest' do
      visit "/resolve/readonly?uri=#{@digital_object.uri}"

      expect(page).to have_css('.iiif-embed iframe', visible: :all)

      # The viewer must not load while its subrecord is collapsed: Universal
      # Viewer sizes itself from the iframe viewport as it loads, so loading
      # while hidden leaves it blank once expanded.
      collapsed_iframe = find('.iiif-embed iframe', visible: :all)
      expect(collapsed_iframe['src'].to_s).to be_empty
      expect(collapsed_iframe['data-iiif-src']).to end_with("/uv/uv.html#?manifest=#{CGI.escape(@manifest_url)}")

      find('.accordion-toggle[href*="_file_version_"]', match: :first).click

      # The src is set once the subrecord has finished expanding, so wait for it
      # rather than reading the attribute the moment the iframe becomes visible.
      expect(page).to have_css('.iiif-embed iframe[src]')

      iiif_iframe = find('.iiif-embed iframe')
      expect(iiif_iframe['src']).to end_with("/uv/uv.html#?manifest=#{CGI.escape(@manifest_url)}")
      expect(iiif_iframe['allow']).to eq('fullscreen')

      within_frame(iiif_iframe) do
        expect(page).to have_content('Simple Manifest - Book', wait: 30)
      end
    end
  end

  context 'when using the bundled Mirador viewer' do
    before(:each) do
      allow(AppConfig).to receive(:[]).and_call_original
      allow(AppConfig).to receive(:has_key?).and_call_original
      allow(AppConfig).to receive(:has_key?).with(:iiif_viewer).and_return(true)
      allow(AppConfig).to receive(:[]).with(:iiif_viewer).and_return('mirador')
    end

    it 'embeds the bundled Mirador viewer and renders the manifest' do
      visit "/resolve/readonly?uri=#{@digital_object.uri}"

      expect(page).to have_css('.iiif-embed iframe', visible: :all)

      collapsed_iframe = find('.iiif-embed iframe', visible: :all)
      expect(collapsed_iframe['src'].to_s).to be_empty
      expect(collapsed_iframe['data-iiif-src']).to end_with("/mirador/index.html?manifest=#{CGI.escape(@manifest_url)}")

      find('.accordion-toggle[href*="_file_version_"]', match: :first).click

      expect(page).to have_css('.iiif-embed iframe[src]')

      iiif_iframe = find('.iiif-embed iframe')
      expect(iiif_iframe['src']).to end_with("/mirador/index.html?manifest=#{CGI.escape(@manifest_url)}")
      expect(iiif_iframe['allow']).to eq('fullscreen')

      within_frame(iiif_iframe) do
        expect(page).to have_content('Simple Manifest - Book', wait: 30)
      end
    end
  end

  context 'when disabled' do
    before(:each) do
      allow(AppConfig).to receive(:[]).and_call_original
      allow(AppConfig).to receive(:has_key?).and_call_original
      allow(AppConfig).to receive(:has_key?).with(:iiif_viewer).and_return(true)
      allow(AppConfig).to receive(:[]).with(:iiif_viewer).and_return('none')
    end

    it 'does not embed a viewer on the digital object page' do
      visit "/resolve/readonly?uri=#{@digital_object.uri}"

      expect(page).to have_css('h3', text: 'File Versions', visible: :all)
      expect(page).to_not have_css('.iiif-embed')
    end

    it 'explains how to configure a viewer' do
      visit "/resolve/readonly?uri=#{@digital_object.uri}"

      expect(page).to have_css('.alert-warning',
                               text: 'No IIIF viewer is available.',
                               visible: :all)
    end
  end
end
