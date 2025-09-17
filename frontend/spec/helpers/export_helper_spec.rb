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
    export = csv_export_with_mappings "#{@repo.uri}/search", Search.build_filters(criteria)
    expect(export).to include("accession,יחסי ציבו")
    expect(export).to include('archival_object,ExportHelper series,ExportHelper collection')
    expect(export).to include('archival_object,ExportHelper item,ExportHelper collection > ExportHelper series')
    expect(export).to include('digital_object_component,ExportHelper digital object component,ExportHelper digital object')
  end

  describe '#map_fields_for_backend' do
    let(:helper) { Object.new.extend(ExportHelper) }

    it 'maps user field names to backend field names' do
      requested_fields = ['type', 'indicator', 'barcode', 'title']
      expected_backend_fields = ['type_enum_s', 'indicator_u_icusort', 'barcode_u_sstr', 'title']
      
      result = helper.map_fields_for_backend(requested_fields)
      expect(result).to eq(expected_backend_fields)
    end

    it 'handles context field specially by including ancestor fields' do
      requested_fields = ['title', 'context', 'type']
      expected_backend_fields = [
        'title',
        'ancestors', 'linked_instance_uris', 'linked_record_uris', 'collection_uri_u_sstr', 'digital_object',
        'type_enum_s'
      ]
      
      result = helper.map_fields_for_backend(requested_fields)
      expect(result).to eq(expected_backend_fields)
    end

    it 'returns unmapped field names as-is when no mapping exists' do
      requested_fields = ['title', 'unknown_field', 'primary_type']
      expected_backend_fields = ['title', 'unknown_field', 'primary_type']
      
      result = helper.map_fields_for_backend(requested_fields)
      expect(result).to eq(expected_backend_fields)
    end

    it 'handles empty array input' do
      requested_fields = []
      expected_backend_fields = []
      
      result = helper.map_fields_for_backend(requested_fields)
      expect(result).to eq(expected_backend_fields)
    end

    it 'handles mixed mapped and unmapped fields with context' do
      requested_fields = ['title', 'type', 'context', 'unknown_field', 'indicator']
      expected_backend_fields = [
        'title',
        'type_enum_s',
        'ancestors', 'linked_instance_uris', 'linked_record_uris', 'collection_uri_u_sstr', 'digital_object',
        'unknown_field',
        'indicator_u_icusort'
      ]
      
      result = helper.map_fields_for_backend(requested_fields)
      expect(result).to eq(expected_backend_fields)
    end
  end

  describe '#csv_export_with_mappings' do
    let(:helper) { Object.new.extend(ExportHelper) }
    
    before do
      # Create test data
      @collection = create(:resource, title: 'Test Collection', level: 'collection')
      @series = create(:archival_object, title: 'Test Series', level: 'series', resource: {ref: @collection.uri})
      @top_container = create(:top_container, type: 'box', indicator: '1', barcode: 'BC001')
      
      run_index_round
    end

    it 'handles basic field mapping without context' do
      # Test basic search without context field
      params = {
        'fields[]' => ['title', 'type', 'indicator'],
        'q' => 'top_container',
        'type[]' => ['top_container']
      }
      
      result = helper.csv_export_with_mappings("#{@repo.uri}/search", params)
      
      # Should contain mapped headers
      expect(result).to include('Title,Type,Indicator')
      # Should contain the data
      expect(result).to include('box')
      expect(result).to include('1')
    end

    it 'automatically maps user field names to backend field names' do
      # Mock the HTTP stream to test field mapping
      mock_csv_response = "type_enum_s,indicator_u_icusort,barcode_u_sstr\nbox,1,BC001\n"
      
      allow(JSONModel::HTTP).to receive(:stream).and_yield(double(body: mock_csv_response))
      
      params = {
        'fields[]' => ['type', 'indicator', 'barcode'],
        'q' => '*'
      }
      
      result = helper.csv_export_with_mappings("/repositories/1/search", params)
      
      # Should map headers to user-friendly names
      expect(result).to include('Type,Indicator,Barcode')
      expect(result).to include('box,1,BC001')
    end

    it 'handles context field by including ancestor fields in backend request' do
      params = {
        'fields[]' => ['title', 'context'],
        'q' => 'archival_object',
        'type[]' => ['archival_object']
      }
      
      result = helper.csv_export_with_mappings("#{@repo.uri}/search", params)
      
      # Should contain context header mapped to user-friendly name
      expect(result).to include('Title,Resource/Accession')
      # Should contain hierarchical context
      expect(result).to include('Test Collection')
    end

    it 'handles mixed field types including context' do
      params = {
        'fields[]' => ['title', 'type', 'context'],
        'q' => 'archival_object',
        'type[]' => ['archival_object']
      }
      
      result = helper.csv_export_with_mappings("#{@repo.uri}/search", params)
      
      # Should contain all mapped headers
      expect(result).to include('Title,Type,Resource/Accession')
      # Should contain the series data with context
      expect(result).to include('Test Series')
      expect(result).to include('Test Collection')
    end

    it 'handles empty fields array gracefully' do
      mock_csv_response = "title\nTest Title\n"
      allow(JSONModel::HTTP).to receive(:stream).and_yield(double(body: mock_csv_response))
      
      params = {
        'fields[]' => [],
        'q' => '*'
      }
      
      result = helper.csv_export_with_mappings("/repositories/1/search", params)
      
      # Should still process the CSV
      expect(result).to include('title')
      expect(result).to include('Test Title')
    end

    it 'preserves field order as requested by user' do
      mock_csv_response = "type_enum_s,title,indicator_u_icusort\nbox,Test Container,1\n"
      allow(JSONModel::HTTP).to receive(:stream).and_yield(double(body: mock_csv_response))
      
      params = {
        'fields[]' => ['type', 'title', 'indicator'],
        'q' => '*'
      }
      
      result = helper.csv_export_with_mappings("/repositories/1/search", params)
      
      # Should preserve the order: Type, Title, Indicator
      lines = result.split("\n")
      expect(lines[0]).to eq('Type,Title,Indicator')
      expect(lines[1]).to eq('box,Test Container,1')
    end

    it 'handles fields with no mapping defined' do
      mock_csv_response = "title,unknown_field,type_enum_s\nTest,Unknown Value,box\n"
      allow(JSONModel::HTTP).to receive(:stream).and_yield(double(body: mock_csv_response))
      
      params = {
        'fields[]' => ['title', 'unknown_field', 'type'],
        'q' => '*'
      }
      
      result = helper.csv_export_with_mappings("/repositories/1/search", params)
      
      # Should keep unmapped field names as-is
      expect(result).to include('title,unknown_field,Type')
      expect(result).to include('Test,Unknown Value,box')
    end

    it 'properly duplicates params to avoid side effects' do
      original_params = {
        'fields[]' => ['type', 'indicator'],
        'q' => 'test',
        'other_param' => 'value'
      }
      
      # Mock the HTTP stream
      mock_csv_response = "type_enum_s,indicator_u_icusort\nbox,1\n"
      allow(JSONModel::HTTP).to receive(:stream) do |uri, params|
        # Verify that backend fields are mapped correctly
        expect(params['fields[]']).to eq(['type_enum_s', 'indicator_u_icusort'])
        # Verify dt=csv is added
        expect(params['dt']).to eq('csv')
        # Verify other params are preserved
        expect(params['other_param']).to eq('value')
        
        double(body: mock_csv_response)
      end
      
      helper.csv_export_with_mappings("/repositories/1/search", original_params)
      
      # Original params should remain unchanged
      expect(original_params['fields[]']).to eq(['type', 'indicator'])
      expect(original_params['dt']).to be_nil
    end
  end

  describe 'CSVMappingConverter' do
    describe '.map_field_name' do
      it 'maps known field names to backend equivalents' do
        expect(ExportHelper::CSVMappingConverter.map_field_name('type')).to eq('type_enum_s')
        expect(ExportHelper::CSVMappingConverter.map_field_name('indicator')).to eq('indicator_u_icusort')
        expect(ExportHelper::CSVMappingConverter.map_field_name('barcode')).to eq('barcode_u_sstr')
      end

      it 'returns unknown field names unchanged' do
        expect(ExportHelper::CSVMappingConverter.map_field_name('title')).to eq('title')
        expect(ExportHelper::CSVMappingConverter.map_field_name('unknown_field')).to eq('unknown_field')
      end
    end

    describe '.ancestor_fields' do
      it 'returns cached ancestor fields' do
        fields = ExportHelper::CSVMappingConverter.ancestor_fields
        expected_fields = ['ancestors', 'linked_instance_uris', 'linked_record_uris', 'collection_uri_u_sstr', 'digital_object']
        
        expect(fields).to eq(expected_fields)
      end

      it 'caches the result for performance' do
        first_call = ExportHelper::CSVMappingConverter.ancestor_fields
        second_call = ExportHelper::CSVMappingConverter.ancestor_fields
        
        expect(first_call.object_id).to eq(second_call.object_id)
      end
    end

    describe '#convert_with_header_mapping' do
      let(:converter) { ExportHelper::CSVMappingConverter.new(['type', 'indicator', 'title']) }

      it 'maps backend headers to user-friendly names' do
        csv_data = [
          ['type_enum_s', 'indicator_u_icusort', 'title'],
          ['box', '1', 'Test Container']
        ]
        
        result = converter.convert_with_header_mapping(csv_data)
        
        expect(result[0]).to eq(['Type', 'Indicator', 'title'])
        expect(result[1]).to eq(['box', '1', 'Test Container'])
      end

      it 'handles context field with ancestor data' do
        converter = ExportHelper::CSVMappingConverter.new(['title', 'context'])
        csv_data = [
          ['title', 'ancestors', 'linked_instance_uris'],
          ['Test Item', '/repositories/1/resources/1,/repositories/1/archival_objects/1', '']
        ]
        
        # Mock the HTTP calls for title lookup
        allow(JSONModel::HTTP).to receive(:get_json)
          .with('/repositories/1/resources/1')
          .and_return({'title' => 'Test Collection'})
        allow(JSONModel::HTTP).to receive(:get_json)
          .with('/repositories/1/archival_objects/1')
          .and_return({'title' => 'Test Series'})
        
        result = converter.convert_with_header_mapping(csv_data)
        
        expect(result[0]).to eq(['title', 'Resource/Accession'])
        expect(result[1][0]).to eq('Test Item')
        expect(result[1][1]).to include('Test Series > Test Collection')
      end

      it 'handles empty CSV data' do
        result = converter.convert_with_header_mapping([])
        expect(result).to eq([])
      end
    end

    describe '#clean_field_value' do
      let(:converter) { ExportHelper::CSVMappingConverter.new([]) }

      it 'handles nil values' do
        expect(converter.send(:clean_field_value, nil)).to be_nil
      end

      it 'removes backslash escaping from commas' do
        dirty_value = 'Item with\, comma'
        clean_value = converter.send(:clean_field_value, dirty_value)
        expect(clean_value).to eq('Item with, comma')
      end

      it 'forces UTF-8 encoding' do
        value = 'test'
        allow(value).to receive(:force_encoding).with('utf-8').and_return(value)
        converter.send(:clean_field_value, value)
        expect(value).to have_received(:force_encoding).with('utf-8')
      end
    end
  end
end
