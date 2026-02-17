require 'spec_helper'

class HandleFacetingTestController < ApplicationController
  include HandleFaceting
  include ManipulateNode
end

describe HandleFacetingTestController, type: :controller do
  describe '#get_pretty_facet_value' do

    it 'translates digital_object_type_enum_s facets' do
      expect(I18n).to receive(:t)
        .with('enumerations.digital_object_digital_object_type.mixed_materials', :default => 'mixed_materials')
        .and_return('Mixed Materials')

      result = subject.get_pretty_facet_value('digital_object_type_enum_s', 'mixed_materials')
      expect(result).to eq('Mixed Materials')
    end

    it 'translates extent_type_enum_s facets' do
      expect(I18n).to receive(:t)
        .with('enumerations.extent_extent_type.linear_feet', :default => 'linear_feet')
        .and_return('Linear Feet')

      result = subject.get_pretty_facet_value('extent_type_enum_s', 'linear_feet')
      expect(result).to eq('Linear Feet')
    end

    it 'translates instance_type_enum_s facets' do
      expect(I18n).to receive(:t)
        .with('enumerations.instance_instance_type.digital_object', :default => 'digital_object')
        .and_return('Digital Object')

      result = subject.get_pretty_facet_value('instance_type_enum_s', 'digital_object')
      expect(result).to eq('Digital Object')
    end

    it 'falls back to raw value when translation is missing' do
      allow(I18n).to receive(:t).and_return('unknown_value')

      result = subject.get_pretty_facet_value('some_type_enum_s', 'unknown_value')
      expect(result).to eq('unknown_value')
    end

    it 'handles container types correctly' do
      expect(I18n).to receive(:t)
        .with('enumerations.container_type.box', :default => 'box')
        .and_return('Box')

      result = subject.get_pretty_facet_value('type_enum_s', 'box')
      expect(result).to eq('Box')
    end

    it 'handles language codes correctly' do
      expect(I18n).to receive(:t)
        .with('enumerations.language_iso639_2.eng', :default => 'eng')
        .and_return('English')

      result = subject.get_pretty_facet_value('langcode', 'eng')
      expect(result).to eq('English')
    end

  end
end
