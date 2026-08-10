# frozen_string_literal: true

# A IIIF Presentation API manifest served by the e2e WireMock stub (see
# wiremock/mappings/iiif-manifest-book.json). The viewer fetches this from the
# browser, so the URL is the WireMock host port and the stubbed response sends
# an Access-Control-Allow-Origin header to permit the cross-origin fetch.
IIIF_MANIFEST_URL = "#{WIREMOCK_URL}/iiif/manifest/book".freeze

# The label declared by the manifest above, rendered by the viewer once it has
# fetched and parsed it.
IIIF_MANIFEST_LABEL = 'Simple Manifest - Book'

Given 'the user has added an IIIF manifest File Version to the Digital Object' do
  click_on 'Add File Version'

  file_version = all('#digital_object_file_versions_ .subrecord-form-list li').last

  within file_version do
    fill_in 'File URI', with: IIIF_MANIFEST_URL
    check 'Publish'
    select 'Text-JSON', from: 'Use Statement'
    select 'embed', from: 'XLink Show Attribute'
    select 'IIIF Manifest', from: 'File Format Name'
  end

  click_on 'Save'
  wait_for_ajax

  expect(page).to have_css('.alert.alert-success.with-hide-alert', text: "Digital Object Digital Object Title #{@uuid} updated")

  @digital_object_number_of_file_versions += 1
end

When 'the user expands the File Version' do
  find('.accordion-toggle[href*="_file_version_"]', match: :first).click
end

When 'the user is on the Digital Object page in the public interface' do
  public_url = "#{PUBLIC_URL}/repositories/#{@repository_id}/digital_objects/#{@digital_object_id}"

  # The record only appears in the public interface once the PUI indexer has
  # picked it up, so retry the visit until it is there.
  tries = 0
  loop do
    visit public_url
    break if page.has_text?("Digital Object Title #{@uuid}", wait: 5)

    tries += 1
    raise "Digital Object was not published to the public interface at #{public_url}" if tries == 12

    sleep 3
  end
end

Then 'the bundled Universal Viewer is embedded' do
  expect(page).to have_css('.iiif-embed iframe[src]')

  iframe = find('.iiif-embed iframe')

  expect(iframe['src']).to end_with "/uv/uv.html#?manifest=#{CGI.escape(IIIF_MANIFEST_URL)}"
  expect(iframe['allow']).to eq 'fullscreen'
end

Then 'the viewer renders the IIIF manifest' do
  within_frame find('.iiif-embed iframe') do
    expect(page).to have_text IIIF_MANIFEST_LABEL, wait: 30
  end
end
