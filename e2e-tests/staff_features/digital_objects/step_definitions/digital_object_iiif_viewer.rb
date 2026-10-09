# frozen_string_literal: true

When 'the user expands the File Version' do
  find('.accordion-toggle[data-target*="_file_version_"]', match: :first).click
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

Then 'no IIIF viewer is embedded' do
  expect(page).not_to have_css('.iiif-embed')
end
