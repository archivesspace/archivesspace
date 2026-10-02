# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe Plugins::AbstractPluginSection do
  let(:section) do
    described_class.new('test_plugin', 'test_section', ['resource'], :sidebar_label => 'Test Section')
  end

  let(:record) { { 'jsonmodel_type' => 'resource' } }

  describe '#render_sidebar' do
    let(:html) { section.render_sidebar(nil, record, :edit) }

    it_behaves_like 'a sidebar link that matches core styling', '#resource_test_section', 'Test Section'
  end
end
