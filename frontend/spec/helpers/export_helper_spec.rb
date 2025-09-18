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

    describe '#build_csv_with_mappings' do
      let(:converter) { ExportHelper::CSVMappingConverter.new(['type', 'indicator', 'title']) }

      it 'maps backend headers to user-friendly names' do
        csv_data = [
          ['type_enum_s', 'indicator_u_icusort', 'title'],
          ['box', '1', 'Test Container']
        ]

        result = converter.build_csv_with_mappings(csv_data)

        expect(result[0]).to eq(['Type', 'Indicator', 'Title'])
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

        result = converter.build_csv_with_mappings(csv_data)

        expect(result[0]).to eq(['Title', 'Resource/Accession'])
        expect(result[1][0]).to eq('Test Item')
        expect(result[1][1]).to include('Test Series > Test Collection')
      end

      it 'handles empty CSV data' do
        result = converter.build_csv_with_mappings([])
        expect(result).to eq([])
      end
    end

    describe '#build_header_row' do
      it 'creates headers for regular fields' do
        converter = ExportHelper::CSVMappingConverter.new(['type', 'indicator', 'title'])
        old_headers = ['type_enum_s', 'indicator_u_icusort', 'title']

        result = converter.send(:build_header_row, old_headers)

        expect(result).to eq(['Type', 'Indicator', 'Title'])
      end

      it 'handles context field specially' do
        converter = ExportHelper::CSVMappingConverter.new(['title', 'context', 'type'])
        old_headers = ['title', 'ancestors', 'type_enum_s']

        result = converter.send(:build_header_row, old_headers)

        expect(result).to eq(['Title', 'Resource/Accession', 'Type'])
      end

      it 'handles unmapped fields by titleizing them' do
        converter = ExportHelper::CSVMappingConverter.new(['title', 'unknown_field'])
        old_headers = ['title', 'unknown_field']

        result = converter.send(:build_header_row, old_headers)

        expect(result).to eq(['Title', 'Unknown Field'])
      end
    end

    describe '#build_data_row' do
      it 'creates data row for regular fields' do
        converter = ExportHelper::CSVMappingConverter.new(['type', 'indicator', 'title'])
        old_headers = ['type_enum_s', 'indicator_u_icusort', 'title']
        old_row = ['box', '1', 'Test Container']

        result = converter.send(:build_data_row, old_row, old_headers)

        expect(result).to eq(['box', '1', 'Test Container'])
      end

      it 'handles context field by building from ancestors' do
        converter = ExportHelper::CSVMappingConverter.new(['title', 'context'])
        old_headers = ['title', 'ancestors', 'linked_instance_uris']
        old_row = ['Test Item', '/repositories/1/resources/1', '']

        # Mock the HTTP call for title lookup
        allow(JSONModel::HTTP).to receive(:get_json)
          .with('/repositories/1/resources/1')
          .and_return({'title' => 'Test Collection'})

        result = converter.send(:build_data_row, old_row, old_headers)

        expect(result[0]).to eq('Test Item')
        expect(result[1]).to eq('Test Collection')
      end

      it 'handles missing field indices gracefully' do
        converter = ExportHelper::CSVMappingConverter.new(['type', 'missing_field'])
        old_headers = ['type_enum_s', 'other_field']
        old_row = ['box', 'other_value']

        result = converter.send(:build_data_row, old_row, old_headers)

        expect(result).to eq(['box', ''])
      end

      it 'cleans field values properly' do
        converter = ExportHelper::CSVMappingConverter.new(['title'])
        old_headers = ['title']
        old_row = ['Test\, with comma']

        result = converter.send(:build_data_row, old_row, old_headers)

        expect(result).to eq(['Test, with comma'])
      end
    end

    describe '#clean_field_value' do
      let(:converter) { ExportHelper::CSVMappingConverter.new([]) }

      it 'handles nil values' do
        expect(converter.clean_field_value(nil)).to eq('')
      end

      it 'handles null string values' do
        expect(converter.clean_field_value('null')).to eq('')
      end

      it 'handles empty string values' do
        expect(converter.clean_field_value('   ')).to eq('')
      end

      it 'removes backslash escaping from commas' do
        dirty_value = 'Item with\, comma'
        clean_value = converter.clean_field_value(dirty_value)
        expect(clean_value).to eq('Item with, comma')
      end

      it 'removes backslash escaping from quotes' do
        dirty_value = 'Item with\\" quote'
        clean_value = converter.clean_field_value(dirty_value)
        expect(clean_value).to eq('Item with" quote')
      end

      it 'removes backslash escaping from single quotes' do
        dirty_value = "Item with\\' quote"
        clean_value = converter.clean_field_value(dirty_value)
        expect(clean_value).to eq("Item with' quote")
      end

      it 'converts newlines to spaces' do
        dirty_value = "Item with\\nline break"
        clean_value = converter.clean_field_value(dirty_value)
        expect(clean_value).to eq('Item with line break')
      end

      it 'converts carriage returns to spaces' do
        dirty_value = "Item with\\rcarriage return"
        clean_value = converter.clean_field_value(dirty_value)
        expect(clean_value).to eq('Item with carriage return')
      end

      it 'forces UTF-8 encoding and strips whitespace' do
        dirty_value = '  test value  '
        clean_value = converter.clean_field_value(dirty_value)
        expect(clean_value).to eq('test value')
        expect(clean_value.encoding).to eq(Encoding::UTF_8)
      end

      it 'handles non-string values by converting to string' do
        clean_value = converter.clean_field_value(123)
        expect(clean_value).to eq('123')
        expect(clean_value.encoding).to eq(Encoding::UTF_8)
      end
    end
  end
end
