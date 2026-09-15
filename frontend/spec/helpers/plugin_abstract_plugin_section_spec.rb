# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe Plugins::AbstractPluginSection do
  let(:section) do
    described_class.new('test_plugin', 'test_section', ['resource'], :sidebar_label => 'Test Section')
  end

  let(:record) { { 'jsonmodel_type' => 'resource' } }

  let(:core_sidebar_link_class) do
    sidebar_partial = File.read(
      File.expand_path('../../app/views/shared/_sidebar.html.erb', __dir__)
    )
    match = sidebar_partial.match(/<a class="([^"]+)" href="#basic_information"/)
    raise "Could not find the Basic Information sidebar link in " \
          "shared/_sidebar.html.erb for comparison. Has its markup changed?" unless match

    match[1]
  end

  describe '#render_sidebar' do
    it 'renders an anchor with the same class as a core sidebar link (so scrollspy can highlight it)' do
      html = section.render_sidebar(nil, record, :edit)

      expect(html).to have_css("a.#{core_sidebar_link_class}")
    end

    it 'links to the section id for the given record type' do
      html = section.render_sidebar(nil, record, :edit)

      expect(html).to have_css('a[href="#resource_test_section"]')
    end

    it 'includes the sidebar label text' do
      html = section.render_sidebar(nil, record, :edit)

      expect(html).to have_content('Test Section')
    end
  end
end
