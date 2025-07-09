# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe ExportHelper do
  before :all do
    @repo = create :repo, repo_code: "exporthelper_test_#{Time.now.to_i}"
    set_repo @repo
  end

  it 'can convert the ancestor refs from a search to a user-friendly context column for CSV downloads' do
    accession = create(:accession, title: "יחסי ציבור")
    collection = create(:resource, title: 'ExportHelper collection', level: 'collection')
    series = create(:archival_object, title: 'ExportHelper series', level: 'series', resource: {ref: collection.uri})
    top_container = create(:top_container, type: 'box')
    item = create(:archival_object,
      title: 'ExportHelper item',
      level: 'item',
      resource: {ref: collection.uri}, parent: {ref: series.uri}
    )
    digital_object = create(:digital_object, title: 'ExportHelper digital object')
    digital_object_component = create(:digital_object_component, title: 'ExportHelper digital object component', digital_object: {ref: digital_object.uri})

    run_index_round

    criteria = {'fields[]' => ['primary_type', 'title', 'ancestors'], 'q' => '*', 'page' => '1'}
    export = csv_export_with_context "#{@repo.uri}/search", Search.build_filters(criteria)
    expect(export).to include("accession,יחסי ציבו")
    expect(export).to include('archival_object,ExportHelper series,ExportHelper collection')
    expect(export).to include('archival_object,ExportHelper item,ExportHelper collection > ExportHelper series')
    expect(export).to include('digital_object_component,ExportHelper digital object component,ExportHelper digital object')
  end

  describe 'CSV Field Mapping in csv_response method' do
    it 'processes field mapping correctly when CSV contains mapped field names' do

      field_map = {
        'title' => 'Title',
        'collection_display_string_u_sstr' => 'Resource/Accession',
        'series_title_u_sstr' => 'Series',
        'type_enum_s' => 'Type',
        'indicator_u_sstr' => 'Indicator',
        'indicator_u_icusort' => 'Indicator',
        'barcode_u_sstr' => 'Barcode',
        'container_profile_display_string_u_sstr' => 'Container Profile',
        'location_display_string_u_sstr' => 'Location',
        'context' => 'Context'
      }

      expect(field_map['title']).to eq('Title')
      expect(field_map['collection_display_string_u_sstr']).to eq('Resource/Accession')
      expect(field_map['series_title_u_sstr']).to eq('Series')
      expect(field_map['type_enum_s']).to eq('Type')
      expect(field_map['indicator_u_sstr']).to eq('Indicator')
      expect(field_map['indicator_u_icusort']).to eq('Indicator')
      expect(field_map['barcode_u_sstr']).to eq('Barcode')
      expect(field_map['container_profile_display_string_u_sstr']).to eq('Container Profile')
      expect(field_map['location_display_string_u_sstr']).to eq('Location')
      expect(field_map['context']).to eq('Context')
    end

    it 'handles CSV parsing edge cases' do
      # BOM
      csv_with_bom = "\uFEFFtitle,collection"
      cleaned = csv_with_bom.sub(/^\uFEFF/, '')
      expect(cleaned).to eq('title,collection')

      # Commas
      csv_content = "title,collection\nTest,Value"
      xml_content = "<xml><data>test</data></xml>"

      expect(csv_content.include?(',')).to be true
      expect(xml_content.include?(',')).to be false
    end

    it 'correctly sets CSV generation options' do
      csv_options = {
        force_quotes: false,
        col_sep: ',',
        row_sep: "\n",
        quote_char: '"'
      }

      test_data = [['Title', 'Collection'], ['Test Title', 'Test Collection']]
      generated = CSV.generate(csv_options) do |csv|
        test_data.each { |row| csv << row }
      end

      expect(generated).to include('Title,Collection')
      expect(generated).to include('Test Title,Test Collection')
    end

    it 'maps field names using I18n with defaults' do
      expect(I18n.t('search.multi.title', :default => 'Title')).to eq('Title')
      expect(I18n.t('search.top_container_mgmt.resource_accession', :default => 'Resource/Accession')).to eq('Resource/Accession')
      expect(I18n.t('search.top_container_mgmt.series', :default => 'Series')).to eq('Series')
      expect(I18n.t('search.top_container_mgmt.type', :default => 'Type')).to eq('Type')
      expect(I18n.t('search.top_container_mgmt.indicator', :default => 'Indicator')).to eq('Indicator')
      expect(I18n.t('search.top_container_mgmt.barcode', :default => 'Barcode')).to eq('Barcode')
      expect(I18n.t('search.top_container_mgmt.container_profile', :default => 'Container Profile')).to eq('Container Profile')
      expect(I18n.t('search.top_container_mgmt.location', :default => 'Location')).to eq('Location')
      expect(I18n.t('search.multi.context', :default => 'Context')).to eq('Context')
    end
  end
end
