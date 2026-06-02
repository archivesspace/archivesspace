# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe ApplicationHelper do
  describe '#primary_language_badge' do
    let(:primary_lang_desc) { { 'is_primary' => true, 'language' => 'eng', 'script' => 'Latn' } }
    let(:other_lang_desc)   { { 'is_primary' => false, 'language' => 'fra', 'script' => 'Latn' } }

    context 'when multilingual content is enabled and in edit mode' do
      before do
        allow(helper).to receive(:edit_mode?).and_return(true)
        allow(AppConfig).to receive(:[]).and_call_original
        allow(AppConfig).to receive(:[]).with(:multilingual_content).and_return(true)
      end

      it 'renders a badge with the primary language code' do
        record = { 'lang_descriptions' => [other_lang_desc, primary_lang_desc] }
        result = helper.primary_language_badge(record)
        expect(result).to include('ENG')
        expect(result).not_to include('FRA')
      end

      it 'returns nil when no lang_descriptions are present' do
        expect(helper.primary_language_badge({})).to be_nil
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
        expect(helper.primary_language_badge(record)).to be_nil
      end
    end
  end
end
