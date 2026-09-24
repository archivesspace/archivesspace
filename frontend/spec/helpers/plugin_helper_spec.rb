# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe PluginHelper do
  let(:record) { { 'jsonmodel_type' => 'resource', 'hello_worlds' => ['one'] } }

  describe '#sidebar_plugins_for' do
    before do
      allow(Plugins).to receive(:plugins_for).with('resource').and_return(['hello_world'])
      allow(Plugins).to receive(:parent_for).with('hello_world', 'resource').and_return({ 'name' => 'hello_worlds' })
      allow(Plugins).to receive(:sections_for).and_return([])
      allow(controller).to receive(:action_name).and_return('edit')
      allow(I18n).to receive(:t).with('plugins.hello_world._plural').and_return('Hello Worlds')
    end

    let(:html) { sidebar_plugins_for(record) }

    it_behaves_like 'a sidebar link that matches core styling', '#resource_hello_worlds_', 'Hello Worlds'
  end
end
