# frozen_string_literal: true

RSpec.shared_examples 'a sidebar link that matches core styling' do |sidebar_href, sidebar_label|
  let(:core_sidebar_link_class) do
    sidebar_partial = File.read(
      File.expand_path('../../app/views/shared/_sidebar.html.erb', __dir__)
    )
    match = sidebar_partial.match(/<a class="([^"]+)" href="#basic_information"/)
    raise "Could not find the Basic Information sidebar link in shared/_sidebar.html.erb" unless match

    match[1]
  end

  it 'renders an anchor with the same class as a core sidebar link (so scrollspy can highlight it)' do
    expect(html).to have_css("a.#{core_sidebar_link_class}")
  end

  it 'links to the section id for the given record type' do
    expect(html).to have_css(%(a[href="#{sidebar_href}"]))
  end

  it 'includes the sidebar label text' do
    expect(html).to have_content(sidebar_label)
  end
end
