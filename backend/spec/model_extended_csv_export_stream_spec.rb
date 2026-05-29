require 'spec_helper'
require 'csv'

describe ExtendedCSVExportStream do

  before(:each) do
    allow(AppConfig).to receive(:[]).and_call_original
    allow(AppConfig).to receive(:[]).with(:extended_csv_export_extra_excluded_properties).and_return([])
    allow(AppConfig).to receive(:[]).with(:extended_csv_export_extra_nested_records).and_return([])
    allow(AppConfig).to receive(:[]).with(:extended_csv_export_max_nested_records).and_return(10)
  end

  def collect_csv(csv_export_stream)
    lines = []
    csv_export_stream.to_csv {|line| lines << line}
    lines
  end

  def parse_csv_output(csv_export_stream)
    lines = collect_csv(csv_export_stream)

    parsed = lines.map {|l| CSV.parse_line(l)}

    headers = parsed.first
    rows = parsed[1..].map {|row| headers.zip(row).to_h}

    [headers, rows]
  end

  describe 'excluded property filtering' do
    ExtendedCSVExportStream::EXCLUDED_PROPERTIES.each do |prop|
      it "excludes the '#{prop}' property" do
        stream = ExtendedCSVExportStream.new
        stream << {prop => 'some_value', 'title' => 'keep'}
        headers, _rows = parse_csv_output(stream)
        expect(headers).not_to include(prop)
        expect(headers).to include('title')
      end
    end

    context 'with extra excluded properties via AppConfig' do
      before(:each) do
        allow(AppConfig).to receive(:[]).with(:extended_csv_export_extra_excluded_properties).and_return(['custom_field'])
      end

      it 'excludes properties listed in AppConfig[:extended_csv_export_extra_excluded_properties]' do
        stream = ExtendedCSVExportStream.new
        stream << {'custom_field' => 'gone', 'title' => 'keep'}
        headers, _rows = parse_csv_output(stream)
        expect(headers).not_to include('custom_field')
        expect(headers).to include('title')
      end
    end
  end

  describe 'reference flattening' do
    it 'flattens a hash with a "ref" key into parent::ref column' do
      stream = ExtendedCSVExportStream.new
      stream << {'repository' => {'ref' => '/repositories/2'}}
      headers, rows = parse_csv_output(stream)
      expect(headers).to include('repository::ref')
      expect(rows.first['repository::ref']).to eq('/repositories/2')
    end

    it 'flattens additional keys in the ref hash' do
      stream = ExtendedCSVExportStream.new
      stream << {'classification' => {'ref' => '/classifications/1', 'display_string' => 'Class A'}}
      headers, rows = parse_csv_output(stream)
      expect(headers).to include('classification::ref', 'classification::display_string')
      expect(rows.first['classification::display_string']).to eq('Class A')
    end

    it 'filters excluded properties within ref hashes' do
      stream = ExtendedCSVExportStream.new
      stream << {'classification' => {'ref' => '/classifications/1', 'lock_version' => 3}}
      headers, _rows = parse_csv_output(stream)
      expect(headers).to include('classification::ref')
      expect(headers).not_to include('classification::lock_version')
    end
  end

  describe 'nested record flattening' do
    context 'dates' do
      it 'flattens a single date into dates::0::field columns' do
        stream = ExtendedCSVExportStream.new
        stream << {
          'title' => 'Test',
          'dates' => [{'begin' => '2020-01-01', 'end' => '2020-12-31', 'date_type' => 'inclusive', 'label' => 'creation'}]
        }
        headers, rows = parse_csv_output(stream)
        expect(headers).to include('dates::0::begin', 'dates::0::end', 'dates::0::date_type', 'dates::0::label')
        expect(rows.first['dates::0::begin']).to eq('2020-01-01')
      end

      it 'flattens multiple dates with incrementing indices' do
        stream = ExtendedCSVExportStream.new
        stream << {
          'title' => 'Test',
          'dates' => [
            {'begin' => '2020-01-01', 'date_type' => 'inclusive'},
            {'begin' => '2021-06-15', 'date_type' => 'single'}
          ]
        }
        headers, rows = parse_csv_output(stream)
        expect(headers).to include('dates::0::begin', 'dates::1::begin')
        expect(rows.first['dates::0::begin']).to eq('2020-01-01')
        expect(rows.first['dates::1::begin']).to eq('2021-06-15')
      end
    end

    context 'extents' do
      it 'flattens extent subrecords into extents::0::field columns' do
        stream = ExtendedCSVExportStream.new
        stream << {
          'title' => 'Test',
          'extents' => [{'number' => '5', 'portion' => 'whole', 'extent_type' => 'linear_feet'}]
        }
        headers, rows = parse_csv_output(stream)
        expect(headers).to include('extents::0::number', 'extents::0::portion', 'extents::0::extent_type')
        expect(rows.first['extents::0::number']).to eq('5')
      end
    end

    context 'instances' do
      it 'flattens instance subrecords' do
        stream = ExtendedCSVExportStream.new
        stream << {
          'title' => 'Test',
          'instances' => [{'instance_type' => 'mixed_materials', 'jsonmodel_type' => 'instance'}]
        }
        headers, rows = parse_csv_output(stream)
        expect(headers).to include('instances::0::instance_type')
        expect(rows.first['instances::0::instance_type']).to eq('mixed_materials')
      end
    end

    context 'with extra nested records via AppConfig' do
      before(:each) do
        allow(AppConfig).to receive(:[]).with(:extended_csv_export_extra_nested_records).and_return(['notes'])
      end

      it 'processes additional nested record types from AppConfig' do
        stream = ExtendedCSVExportStream.new
        stream << {
          'title' => 'Test',
          'notes' => [{'type' => 'abstract', 'content' => 'A note'}]
        }
        headers, _rows = parse_csv_output(stream)
        expect(headers).to include('notes::0::type', 'notes::0::content')
      end
    end
  end

  describe 'custom extractors' do
    describe 'extract_subject' do
      it 'extracts only source, title, and uri from a resolved subject' do
        stream = ExtendedCSVExportStream.new
        stream << {
          'title' => 'Test',
          'subjects' => [{
                           'ref' => '/subjects/1',
                           '_resolved' => {
                             'jsonmodel_type' => 'subject',
                             'title' => 'History',
                             'source' => 'lcsh',
                             'uri' => '/subjects/1',
                             'terms' => [{'term' => 'History'}],
                             'vocabulary' => '/vocabularies/1',
                             'authority_id' => 'sh12345'
                           }
                         }]
        }
        headers, rows = parse_csv_output(stream)

        subject_headers = headers.select {|h| h.start_with?('subjects::0::')}
        expect(subject_headers).to contain_exactly('subjects::0::source', 'subjects::0::title', 'subjects::0::uri')
        expect(rows.first['subjects::0::title']).to eq('History')
        expect(rows.first['subjects::0::source']).to eq('lcsh')
      end

      it 'does not include terms, vocabulary, or other non-selected fields' do
        stream = ExtendedCSVExportStream.new
        stream << {
          'title' => 'Test',
          'subjects' => [{
                           'ref' => '/subjects/1',
                           '_resolved' => {
                             'jsonmodel_type' => 'subject',
                             'title' => 'History',
                             'source' => 'lcsh',
                             'uri' => '/subjects/1',
                             'terms' => [{'term' => 'History'}],
                             'vocabulary' => '/vocabularies/1'
                           }
                         }]
        }
        headers, _rows = parse_csv_output(stream)
        expect(headers).not_to include('subjects::0::vocabulary')
        expect(headers).not_to include('subjects::0::authority_id')
      end
    end

    describe 'extract_agent' do
      %w[agent_person agent_family agent_corporate_entity agent_software].each do |agent_type|
        it "extracts all scalar properties from a resolved #{agent_type}" do
          stream = ExtendedCSVExportStream.new
          stream << {
            'title' => 'Test',
            'linked_agents' => [{
                                  'ref' => "/agents/#{agent_type}/1",
                                  '_resolved' => {
                                    'jsonmodel_type' => agent_type,
                                    'title' => 'Agent Name',
                                    'uri' => "/agents/#{agent_type}/1",
                                    'display_name' => {'sort_name' => 'Name, Agent'}
                                  }
                                }]
          }
          headers, rows = parse_csv_output(stream)

          expect(headers).to include("linked_agents::0::title")
          expect(rows.first["linked_agents::0::title"]).to eq('Agent Name')
        end
      end
    end
  end

  describe 'max nested records limit' do
    before(:each) do
      allow(AppConfig).to receive(:[]).with(:extended_csv_export_max_nested_records).and_return(2)
    end

    it 'processes nested records below the limit normally' do
      stream = ExtendedCSVExportStream.new
      stream << {
        'title' => 'Test',
        'dates' => [
          {'begin' => '2020-01-01'},
          {'begin' => '2021-01-01'}
        ]
      }
      _headers, rows = parse_csv_output(stream)
      expect(rows.first['dates::0::begin']).to eq('2020-01-01')
      expect(rows.first['dates::1::begin']).to eq('2021-01-01')
    end

    it 'replaces values with MAX_NESTED_RECORDS_REACHED at the limit index' do
      stream = ExtendedCSVExportStream.new
      stream << {
        'title' => 'Test',
        'dates' => [
          {'begin' => '2020-01-01'},
          {'begin' => '2021-01-01'},
          {'begin' => '2022-01-01'}  # index 2 == max_nested
        ]
      }
      _headers, rows = parse_csv_output(stream)
      expect(rows.first['dates::2::begin']).to eq('MAX_NESTED_RECORDS_REACHED')
    end

    it 'skips nested records beyond the limit' do
      stream = ExtendedCSVExportStream.new
      stream << {
        'title' => 'Test',
        'dates' => [
          {'begin' => '2020-01-01'},
          {'begin' => '2021-01-01'},
          {'begin' => '2022-01-01'},
          {'begin' => '2023-01-01'}  # index 3 > max_nested, skipped
        ]
      }
      headers, _rows = parse_csv_output(stream)
      expect(headers).not_to include('dates::3::begin')
    end
  end

  describe 'header sorting' do
    it 'prioritizes jsonmodel_type, uri, title, display_string at the top' do
      stream = ExtendedCSVExportStream.new
      stream << {'zzz_field' => 'val', 'title' => 'val', 'uri' => 'val', 'jsonmodel_type' => 'resource', 'display_string' => 'val'}
      headers, _rows = parse_csv_output(stream)
      priority_fields = headers.first(4)
      expect(priority_fields).to eq(%w[jsonmodel_type uri title display_string])
    end

    it 'places finding_aid_ prefixed fields early' do
      stream = ExtendedCSVExportStream.new
      stream << {'zzz_field' => 'val', 'finding_aid_title' => 'val', 'finding_aid_status' => 'val', 'title' => 'val'}
      headers, _rows = parse_csv_output(stream)
      fa_title_idx = headers.index('finding_aid_title')
      fa_status_idx = headers.index('finding_aid_status')
      zzz_idx = headers.index('zzz_field')
      expect(fa_title_idx).to be < zzz_idx
      expect(fa_status_idx).to be < zzz_idx
    end

    it 'places id_0 through id_3 before general fields' do
      stream = ExtendedCSVExportStream.new
      stream << {'zzz_field' => 'val', 'id_0' => '1', 'id_1' => '2'}
      headers, _rows = parse_csv_output(stream)
      expect(headers.index('id_0')).to be < headers.index('zzz_field')
      expect(headers.index('id_1')).to be < headers.index('zzz_field')
    end

    it 'groups nested record columns together by prefix' do
      stream = ExtendedCSVExportStream.new
      stream << {
        'title' => 'Test',
        'dates' => [{'begin' => '2020', 'end' => '2021'}],
        'extents' => [{'number' => '5', 'portion' => 'whole'}]
      }
      headers, _rows = parse_csv_output(stream)

      dates_indices = headers.each_index.select {|i| headers[i].start_with?('dates::')}
      extents_indices = headers.each_index.select {|i| headers[i].start_with?('extents::')}

      # All dates columns are together
      expect(dates_indices).to eq((dates_indices.min..dates_indices.max).to_a)

      # All extents columns are together
      expect(extents_indices).to eq((extents_indices.min..extents_indices.max).to_a)
    end

    it 'orders date subfields correctly: date_type, label, begin, end, expression' do
      stream = ExtendedCSVExportStream.new
      stream << {
        'title' => 'Test',
        'dates' => [{'expression' => 'circa 2020', 'end' => '2020-12-31', 'begin' => '2020-01-01', 'label' => 'creation', 'date_type' => 'inclusive'}]
      }
      headers, _rows = parse_csv_output(stream)
      date_headers = headers.select {|h| h.start_with?('dates::0::')}

      expected_order = %w[dates::0::date_type dates::0::label dates::0::begin dates::0::end dates::0::expression]
      expect(date_headers).to eq(expected_order)
    end

    it 'orders extent subfields correctly: number, portion, type' do
      stream = ExtendedCSVExportStream.new
      stream << {
        'title' => 'Test',
        'extents' => [{'extent_type' => 'linear_feet', 'portion' => 'whole', 'number' => '5'}]
      }
      headers, _rows = parse_csv_output(stream)
      extent_headers = headers.select {|h| h.start_with?('extents::0::')}

      expected_order = %w[extents::0::number extents::0::portion extents::0::extent_type]
      expect(extent_headers).to eq(expected_order)
    end

    it 'sorts nested indices numerically (::2:: before ::10::)' do
      stream = ExtendedCSVExportStream.new
      record = {'title' => 'Test', 'dates' => []}
      11.times {|i| record['dates'] << {'begin' => "20#{sprintf('%02d', i)}-01-01"}}

      stream << record
      headers, _rows = parse_csv_output(stream)
      date_begin_headers = headers.select {|h| h =~ /\Adates::\d+::begin\z/}
      indices = date_begin_headers.map {|h| Integer(h.split('::')[1])}
      expect(indices).to eq(indices.sort)
    end
  end

  describe 'multiple records with different schemas' do
    it 'produces headers that are the union of all record fields' do
      stream = ExtendedCSVExportStream.new
      stream << {'title' => 'First', 'level' => 'collection'}
      stream << {'title' => 'Second', 'uri' => '/resources/1'}
      headers, _rows = parse_csv_output(stream)
      expect(headers).to include('title', 'level', 'uri')
    end

    it 'fills missing fields with nil (empty CSV cells)' do
      stream = ExtendedCSVExportStream.new
      stream << {'title' => 'First', 'level' => 'collection'}
      stream << {'title' => 'Second', 'uri' => '/resources/1'}
      _headers, rows = parse_csv_output(stream)
      expect(rows[0]['uri']).to be_nil
      expect(rows[1]['level']).to be_nil
    end
  end

  describe 'edge cases' do
    it 'handles an empty hash without writing a data row' do
      stream = ExtendedCSVExportStream.new
      stream << {}
      lines = collect_csv(stream)
      # Only the header row should be present
      expect(lines.length).to eq(1)
    end

    it 'handles a record where all properties are excluded' do
      stream = ExtendedCSVExportStream.new
      stream << {'lock_version' => 1, '_resolved' => {}, 'system_mtime' => '2020-01-01'}
      lines = collect_csv(stream)
      # Only the header row should be present
      expect(lines.length).to eq(1)
    end
  end
end
