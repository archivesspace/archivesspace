# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe ApplicationHelper do
  describe '#description_language_badge' do
    let(:primary_lang_desc) { { 'is_primary' => true, 'language' => 'eng', 'script' => 'Latn' } }
    let(:other_lang_desc)   { { 'is_primary' => false, 'language' => 'fra', 'script' => 'Latn' } }

    context 'when multilingual content is enabled and in edit mode' do
      before do
        allow(helper).to receive(:edit_mode?).and_return(true)
        allow(AppConfig).to receive(:[]).and_call_original
        allow(AppConfig).to receive(:[]).with(:multilingual_content).and_return(true)
      end

      it 'defaults to the primary language code when none is selected' do
        record = { 'jsonmodel_type' => 'resource', 'lang_descriptions' => [other_lang_desc, primary_lang_desc] }
        result = helper.description_language_badge(record)
        expect(result).to include('ENG')
        expect(result).not_to include('FRA')
      end

      it 'returns nil for a resource with only one lang_description' do
        record = { 'jsonmodel_type' => 'resource', 'lang_descriptions' => [primary_lang_desc] }
        expect(helper.description_language_badge(record)).to be_nil
      end

      it 'returns nil for a resource with no lang_descriptions' do
        record = { 'jsonmodel_type' => 'resource', 'lang_descriptions' => [] }
        expect(helper.description_language_badge(record)).to be_nil
      end

      it 'does not inherit lang_descriptions from a parent for record types that carry their own' do
        parent = { 'lang_descriptions' => [other_lang_desc, primary_lang_desc] }
        record = { 'jsonmodel_type' => 'resource', 'lang_descriptions' => [], 'resource' => { '_resolved' => parent } }
        expect(helper.description_language_badge(record)).to be_nil
      end

      it 'uses the parent resource lang_descriptions for an archival_object' do
        parent = { 'lang_descriptions' => [other_lang_desc, primary_lang_desc] }
        record = { 'jsonmodel_type' => 'archival_object', 'resource' => { '_resolved' => parent } }
        result = helper.description_language_badge(record)
        expect(result).to include('ENG')
        expect(result).not_to include('FRA')
      end

      it 'uses the parent digital_object lang_descriptions for a digital_object_component' do
        parent = { 'lang_descriptions' => [other_lang_desc, primary_lang_desc] }
        record = { 'jsonmodel_type' => 'digital_object_component', 'digital_object' => { '_resolved' => parent } }
        result = helper.description_language_badge(record)
        expect(result).to include('ENG')
      end

      it 'returns nil for an archival_object whose parent has only one lang_description' do
        parent = { 'lang_descriptions' => [primary_lang_desc] }
        record = { 'jsonmodel_type' => 'archival_object', 'resource' => { '_resolved' => parent } }
        expect(helper.description_language_badge(record)).to be_nil
      end

      it 'returns nil for an archival_object with no resolved parent' do
        record = { 'jsonmodel_type' => 'archival_object', 'resource' => nil }
        expect(helper.description_language_badge(record)).to be_nil
      end

      it 'uses the selected non-primary language when language_of_description is set' do
        allow(helper).to receive(:params).and_return(ActionController::Parameters.new(language_of_description: 'fra_Latn'))
        record = { 'jsonmodel_type' => 'resource', 'lang_descriptions' => [other_lang_desc, primary_lang_desc] }
        result = helper.description_language_badge(record)
        expect(result).to include('FRA')
        expect(result).not_to include('ENG')
      end

      it 'falls back to the primary language when the selected language does not match a lang_description' do
        allow(helper).to receive(:params).and_return(ActionController::Parameters.new(language_of_description: 'spa_Latn'))
        record = { 'jsonmodel_type' => 'resource', 'lang_descriptions' => [other_lang_desc, primary_lang_desc] }
        result = helper.description_language_badge(record)
        expect(result).to include('ENG')
      end
    end

    context 'when multilingual content is disabled' do
      before do
        allow(helper).to receive(:edit_mode?).and_return(true)
        allow(AppConfig).to receive(:[]).and_call_original
        allow(AppConfig).to receive(:[]).with(:multilingual_content).and_return(false)
      end

      it 'returns nil regardless of lang_descriptions' do
        record = { 'lang_descriptions' => [primary_lang_desc] }
        expect(helper.description_language_badge(record)).to be_nil
      end
    end
  end

  describe '#render_token' do
    let(:token_options) do
      {
        uri: '/repositories/1/resources/2',
        type: 'resource',
        label: +'Test Label'
      }
    end

    it 'renders the token as a direct link without popover behavior' do
      html = helper.render_token(token_options)

      expect(html).to include('href="/resolve/readonly?uri=/repositories/1/resources/2"')
      expect(html).to include('class="token resource"')
      expect(html).not_to include('data-toggle="popover"')
    end

    it 'does not open the link in a new tab in readonly contexts' do
      html = helper.render_token(token_options)

      expect(html).not_to include('target="_blank"')
    end

    it 'opens the link in a new tab in linker contexts' do
      html = helper.render_token(**token_options, inside_linker_browse: true)

      expect(html).to include('target="_blank"')
    end

    it 'renders the token icon when an icon class is provided' do
      html = helper.render_token(**token_options, icon_class: 'icon-book')

      expect(html).to include("<span class='icon-token icon-book'></span>")
    end

    it 'renders edit mode tokens without readonly token styling' do
      html = helper.render_token(**token_options, inside_token_editor: true)

      expect(html).not_to include('class="token resource"')
    end
  end
end
