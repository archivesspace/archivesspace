# frozen_string_literal: true

require 'spec_helper'

# Kept separate from model_preference_spec.rb, which swaps out the real `defaults` schema.
describe 'Defaults actions column position' do
  let(:record_types) { SearchAndBrowseColumnConfig.columns.keys }

  it 'defines an actions column position property for every search and browse record type' do
    properties = JSONModel(:defaults).schema['properties']

    record_types.each do |type|
      expect(properties).to include("#{type}_actions_column_position")
      # The backend spec helper enables allow_other_unmapped, which adds 'other_unmapped' to every enum.
      expect(properties["#{type}_actions_column_position"]['enum'] - ['other_unmapped']).to eq(['start', 'end'])
    end
  end

  it 'accepts start and end' do
    ['start', 'end'].each do |position|
      expect {
        JSONModel(:defaults).from_hash('accession_actions_column_position' => position)
      }.not_to raise_error
    end
  end

  it 'accepts an empty value, which inherits the position from a broader scope' do
    expect {
      JSONModel(:defaults).from_hash('accession_actions_column_position' => '')
    }.not_to raise_error
  end

  it 'rejects any other value' do
    ['left', 'right', 'middle'].each do |position|
      expect {
        JSONModel(:defaults).from_hash('accession_actions_column_position' => position)
      }.to raise_error(JSONModel::ValidationException)
    end
  end

  it 'gives every record type a valid built-in default of start' do
    defaults = PreferenceConfig.defaults

    record_types.each do |type|
      expect(defaults["#{type}_actions_column_position"]).to eq('start')
    end
  end

  it 'loads valid built-in defaults into a preference record' do
    expect {
      JSONModel(:preference).from_hash('defaults' => PreferenceConfig.defaults.slice(
        *record_types.map { |type| "#{type}_actions_column_position" }
      ))
    }.not_to raise_error
  end
end
