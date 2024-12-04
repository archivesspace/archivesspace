require 'spec_helper'
require 'converter_spec_helper'

require_relative '../app/converters/marcxml_auth_agent_converter'

describe 'MARCXML Auth Agent converter' do
  def my_converter
    MarcXMLAuthAgentConverter
  end

  let(:person_agent_1) do
    File.expand_path('./examples/marc/authority_john_davis.xml',
                     File.dirname(__FILE__))
  end

  let(:person_agent_2) do
    File.expand_path('./examples/marc/authority_john_davis_2.xml',
                     File.dirname(__FILE__))
  end

  let(:corporate_agent_1) do
    File.expand_path('./examples/marc/IAS.xml',
                     File.dirname(__FILE__))
  end

  let(:corporate_agent_2) do
    File.expand_path('./examples/marc/IAS_2.xml',
                     File.dirname(__FILE__))
  end

  let(:family_agent_1) do
    File.expand_path('./examples/marc/Wood.xml',
                     File.dirname(__FILE__))
  end

  let(:agent_collection) do
    File.expand_path('./examples/marc/marcxml_collection_with_multiple_records.xml',
                     File.dirname(__FILE__))
  end

  let(:authority_agent_other_standard_identifier_a) do
    File.expand_path('./examples/marc/authority_agent_other_standard_identifier_a.xml',
                     File.dirname(__FILE__))
  end

  let(:authority_agent_other_standard_identifier_0) do
    File.expand_path('./examples/marc/authority_agent_other_standard_identifier_0.xml',
                     File.dirname(__FILE__))
  end

  let(:authority_agent_other_standard_identifier_both) do
    File.expand_path('./examples/marc/authority_agent_other_standard_identifier_both.xml',
                     File.dirname(__FILE__))
  end

  describe 'agent person' do
    before(:all) do
    end

    it 'converts agent name from marc auth (indirect)' do
      record = convert(person_agent_1).select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      expect(record['names'][0]['primary_name']).to eq('Davis')
      expect(record['names'][0]['number']).to eq('IV')
      expect(record['names'][0]['title']).to eq('Dr.')
      expect(record['names'][0]['qualifier']).to eq('qualifier')
      expect(record['names'][0]['fuller_form']).to eq('fuller_form')
      expect(record['names'][0]['dates']).to eq('1873-1955')
      expect(record['names'][0]['authorized']).to eq(true)
    end

    it 'converts agent name from marc auth (direct)' do
      record = convert(person_agent_2).select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      expect(record['names'][0]['primary_name']).to eq('Davis')
      expect(record['names'][0]['number']).to eq('IV')
      expect(record['names'][0]['title']).to eq('Dr.')
      expect(record['names'][0]['qualifier']).to eq('qualifier')
      expect(record['names'][0]['fuller_form']).to eq('378 fuller')
      expect(record['names'][0]['dates']).to eq('1873-1955')
      expect(record['names'][0]['authorized']).to eq(true)
    end

    it 'imports parallel names' do
      record = convert(person_agent_1).select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      expect(record['names'].length).to eq(2)
      expect(record['names'][1]['primary_name']).to eq('Davis')
    end

    it 'imports dates of existence' do
      record = convert(person_agent_1).select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      expect(record['dates_of_existence'][0]['structured_date_range']['begin_date_expression']).to eq('18990101')
      expect(record['dates_of_existence'][0]['structured_date_range']['end_date_expression']).to eq('19611201')
    end

    it 'imports agent gender' do
      record = convert(person_agent_1).select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      expect(record['agent_genders'][0]['gender']).to eq('Male')
    end

    it 'imports topics' do
      record = convert(person_agent_1).select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      expect(record['agent_topics'].length).to eq(1)
    end

    it 'does not import topics if subject import disabled' do
      record = convert(person_agent_1, false, false).select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      expect(record['agent_topics'].length).to eq(0)
    end
  end

  describe 'agent family' do
    it 'imports name' do
      record = convert(family_agent_1).select { |r| r['jsonmodel_type'] == 'agent_family' }.first

      expect(record['names'][0]['family_name']).to eq('Wood, Natalie')
      expect(record['names'][0]['qualifier']).to eq('qualifier')
      expect(record['names'][0]['dates']).to eq('1873-1955')
      expect(record['names'][0]['authorized']).to eq(true)
    end

    it 'imports parallel names' do
      record = convert(family_agent_1).select { |r| r['jsonmodel_type'] == 'agent_family' }.first

      expect(record['names'].length).to eq(9)
      expect(record['names'][1]['family_name']).to eq('Gurdin, Natasha,')
      expect(record['names'][1]['authorized']).to eq(false)
    end

    it 'imports dates of existence' do
      record = convert(family_agent_1).select { |r| r['jsonmodel_type'] == 'agent_family' }.first

      expect(record['dates_of_existence'][0]['structured_date_range']['begin_date_expression']).to eq('1938-07-20')
      expect(record['dates_of_existence'][0]['structured_date_range']['end_date_expression']).to eq('1981-11-29')
    end

    it 'imports functions' do
      record = convert(family_agent_1).select { |r| r['jsonmodel_type'] == 'agent_family' }.first

      expect(record['agent_functions'].length).to eq(1)
    end

    it 'does not import functions if subject import disabled' do
      record = convert(family_agent_1 , false, false).select { |r| r['jsonmodel_type'] == 'agent_family' }.first

      expect(record['agent_functions'].length).to eq(0)
    end
  end

  describe 'agent_corporate_entity' do
    it 'imports name' do
      record = convert(corporate_agent_1).select { |r| r['jsonmodel_type'] == 'agent_corporate_entity' }.first

      expect(record['names'][0]['primary_name']).to eq('Institute for Advanced Study (Princeton, N.J.)')
      expect(record['names'][0]['authorized']).to eq(true)
      expect(record['names'][0]['conference_meeting']).to eq(false)
      expect(record['names'][0]['subordinate_name_1']).to eq('sub name 1')
      expect(record['names'][0]['location']).to eq('Miami')
      expect(record['names'][0]['dates']).to eq('1999')
      expect(record['names'][0]['number']).to eq('3')
      expect(record['names'][0]['qualifier']).to eq('qualifier')
    end

    it 'imports name (conference) to qualifier for 111 tags' do
      record = convert(corporate_agent_2).select { |r| r['jsonmodel_type'] == 'agent_corporate_entity' }.first

      expect(record['names'][0]['primary_name']).to eq('Institute for Advanced Study (Princeton, N.J.)')
      expect(record['names'][0]['authorized']).to eq(true)
      expect(record['names'][0]['conference_meeting']).to eq(true)
      expect(record['names'][0]['subordinate_name_1']).to eq('sub name 1')
      expect(record['names'][0]['location']).to eq('Miami')
      expect(record['names'][0]['dates']).to eq('1999')
      expect(record['names'][0]['number']).to eq('3')
      expect(record['names'][0]['qualifier']).to eq('Name of meeting following jurisdiction name entry element: sub name 2')
    end

    it 'imports parallel names' do
      record = convert(corporate_agent_1).select { |r| r['jsonmodel_type'] == 'agent_corporate_entity' }.first

      expect(record['names'].length).to eq(4)
      expect(record['names'][1]['primary_name']).to eq('Louis Bamberger and Mrs. Felix Fuld Foundation')
      expect(record['names'][1]['authorized']).to eq(false)
    end

    it 'imports dates of existence' do
      record = convert(corporate_agent_1).select { |r| r['jsonmodel_type'] == 'agent_corporate_entity' }.first

      expect(record['dates_of_existence'][0]['structured_date_single']['date_expression']).to eq('1930-05-20')
      expect(record['dates_of_existence'][0]['structured_date_single']['date_role']).to eq('begin')
    end

    it 'imports functions' do
      record = convert(corporate_agent_1).select { |r| r['jsonmodel_type'] == 'agent_corporate_entity' }.first

      expect(record['agent_functions'].length).to eq(1)
    end

    it 'does not import functions if subject import disabled' do
      record = convert(corporate_agent_1, false, false).select { |r| r['jsonmodel_type'] == 'agent_corporate_entity' }.first

      expect(record['agent_functions'].length).to eq(0)
    end
  end

  describe 'common subrecords' do
    it 'imports agent_record_control' do
      record = convert(person_agent_1).select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      expect(record['agent_record_controls'][0]['maintenance_status']).to eq('revised_corrected')
      expect(record['agent_record_controls'][0]['maintenance_agency']).to eq('DLC')
      expect(record['agent_record_controls'][0]['romanization']).to eq('not_applicable')
      expect(record['agent_record_controls'][0]['language']).to eq('mul')
      expect(record['agent_record_controls'][0]['government_agency_type']).to eq('unknown')
      expect(record['agent_record_controls'][0]['reference_evaluation']).to eq('tr_consistent')
      expect(record['agent_record_controls'][0]['name_type']).to eq('differentiated')
      expect(record['agent_record_controls'][0]['level_of_detail']).to eq('fully_established')
      expect(record['agent_record_controls'][0]['modified_record']).to eq('not_modified')
      expect(record['agent_record_controls'][0]['cataloging_source']).to eq('nat_bib_agency')
    end

    it 'imports agent_record_identifiers' do
      record = convert(person_agent_1).select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      # From 010
      expect(record['agent_record_identifiers'][0]['record_identifier']).to eq('n  88218900 ')
      expect(record['agent_record_identifiers'][0]['identifier_type']).to eq('loc')
      expect(record['agent_record_identifiers'][0]['source']).to eq('naf')
      expect(record['agent_record_identifiers'][0]['primary_identifier']).to eq(true)

      # From 035
      expect(record['agent_record_identifiers'][1]['record_identifier']).to eq('n  88218900')
      expect(record['agent_record_identifiers'][1]['identifier_type']).to eq('local')
      expect(record['agent_record_identifiers'][1]['source']).to eq('DLC')
      expect(record['agent_record_identifiers'][1]['primary_identifier']).to eq(false)
    end

    it 'imports authority_agent_other_standard_identifier_a to the correct agent' do
      records = convert(authority_agent_other_standard_identifier_a).select { |r| r['jsonmodel_type'] == 'agent_person' }
      expect(records[0]['agent_record_identifiers'][1]['record_identifier']).to eq('http://viaf.org/viaf/91053810')
      expect(records[0]['agent_record_identifiers'][1]['primary_identifier']).to eq(false)
    end

    it 'imports authority_agent_other_standard_identifier_0 to the correct agent' do
      records = convert(authority_agent_other_standard_identifier_0).select { |r| r['jsonmodel_type'] == 'agent_person' }
      expect(records[0]['agent_record_identifiers'][1]['record_identifier']).to eq('viaf91053810')
      expect(records[0]['agent_record_identifiers'][1]['primary_identifier']).to eq(false)
    end

    it 'imports authority_agent_other_standard_identifier_both to the correct agent' do
      records = convert(authority_agent_other_standard_identifier_both).select { |r| r['jsonmodel_type'] == 'agent_person' }
      expect(records[0]['agent_record_identifiers'][1]['record_identifier']).to eq('10.25555/uhhfdm.777')
      expect(records[0]['agent_record_identifiers'][1]['primary_identifier']).to eq(false)
    end

    it 'imports agent_record_identifier from 035 prepended with (DLC) with proper source and type' do
      record = convert(person_agent_2).select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      expect(record['agent_record_identifiers'][1]['record_identifier']).to eq('(DLC)n  88218900')
      expect(record['agent_record_identifiers'][1]['identifier_type']).to eq('loc')
      expect(record['agent_record_identifiers'][1]['source']).to eq('naf')
    end

    it 'does not import record_identifier from 001 when 003 is DLC and 010 is present' do
      record = convert(person_agent_1).select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      # From 001
      expect(record['agent_record_identifiers']).not_to include(:record_identifier => 'n88218900')
    end

    it 'imports agent_maintenance_histories' do
      record = convert(person_agent_1, true).select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      expect(record['agent_maintenance_histories'][0]['event_date']).to eq('19890119')
      expect(record['agent_maintenance_histories'][0]['maintenance_event_type']).to eq('created')
      expect(record['agent_maintenance_histories'][0]['maintenance_agent_type']).to eq('machine')
      expect(record['agent_maintenance_histories'][0]['agent']).to eq('DLC')
    end

    it 'does not create pre-1970 agent_maintenance_history event_dates' do
      record = convert(authority_agent_other_standard_identifier_a, true)
        .select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      expect(record['agent_maintenance_histories'][0]['event_date']).to eq('20090721')
      expect(record['agent_maintenance_histories'][0]['maintenance_event_type']).to eq('created')
      expect(record['agent_maintenance_histories'][0]['maintenance_agent_type']).to eq('machine')
      expect(record['agent_maintenance_histories'][0]['agent']).to eq('Missing in File')
    end

    it 'does not import agent_maintenance_histories if option not set' do
      record = convert(person_agent_1, false).select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      expect(record['agent_maintenance_histories'].count.zero?).to eq(true)
    end

    it 'imports unique maintenance orgs into agent_other_agency_codes' do
      record = convert(corporate_agent_1, true).select { |r| r['jsonmodel_type'] == 'agent_corporate_entity' }.first

      expect(record['agent_other_agency_codes'].count.zero?).to eq(false)
      expect(record['agent_other_agency_codes'][0]['maintenance_agency']).to eq('CU-S')
    end

    it 'does not import maintenance orgs into agent_other_agency_codes that duplicate agent_maintenance_histories' do
      record = convert(person_agent_1, true).select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      expect(record['agent_other_agency_codes'].count.zero?).to eq(true)
    end

    it 'imports agent_conventions_declarations' do
      record = convert(person_agent_1).select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      expect(record['agent_conventions_declarations'][0]['name_rule']).to eq('AACR2')
    end

    it 'imports places of birth' do
      raw = convert(person_agent_1)

      record = raw.select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      place = record['agent_places'].select { |ap| ap['place_role'] == 'place_of_birth' }

      expect(place.length).to eq(1)
    end

    it 'imports places of death' do
      raw = convert(person_agent_1)

      record = raw.select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      place = record['agent_places'].select { |ap| ap['place_role'] == 'place_of_death' }

      expect(place.length).to eq(1)
    end

    it 'imports places of associated country' do
      raw = convert(person_agent_1)

      record = raw.select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      place = record['agent_places'].select { |ap| ap['place_role'] == 'assoc_country' }

      expect(place.length).to eq(1)
    end

    it 'imports places of residence' do
      raw = convert(person_agent_1)

      record = raw.select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      place = record['agent_places'].select { |ap| ap['place_role'] == 'residence' }

      expect(place.length).to eq(1)
    end

    it 'imports places of other associated' do
      raw = convert(person_agent_1)

      record = raw.select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      place = record['agent_places'].select { |ap| ap['place_role'] == 'other_assoc' }

      expect(place.length).to eq(1)
    end

    it 'imports occupation' do
      raw = convert(person_agent_1)

      record = raw.select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      expect(record['agent_occupations'].length).to eq(1)
    end

    it 'imports used language from $a' do
      raw = convert(person_agent_1)

      record = raw.select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      expect(record['used_languages'][0]['language']).to eq('eng')
    end

    it 'imports used language from value in $l if $a is not defined' do
      raw = convert(person_agent_2)

      record = raw.select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      expect(record['used_languages'][0]['language']).to eq('fre')
    end

    it 'imports related agents' do
      raw = convert(corporate_agent_1)
      agent_corp_records = raw.select { |r| r['jsonmodel_type'] == 'agent_corporate_entity' }
      agent_person_records = raw.select { |r| r['jsonmodel_type'] == 'agent_person' }

      expect(agent_corp_records.length).to eq(1)
      expect(agent_person_records.length).to eq(1)

      # relationships are there
      expect(agent_corp_records.last['related_agents']).not_to be_nil
      expect(agent_corp_records.last['related_agents'].first['jsonmodel_type']).to eq('agent_relationship_associative')
      expect(agent_corp_records.last['related_agents'].first['description']).to eq('Founder:')
      # related agent is there
      expect(agent_person_records.first['names'][0]['primary_name']).to eq('Flexner')
      expect(agent_person_records.first['names'][0]['rest_of_name']).to eq('Abraham')
    end

    it 'imports agent_sources subrecords' do
      raw = convert(person_agent_1)

      record = raw.select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      expect(record['agent_sources'][0]['source_entry']).to eq('NUCMC data from Washington and Lee University Lib. for Gaines, F. Papers, 1903-1982')
      expect(record['agent_sources'][0]['descriptive_note']).to eq('(Davis, John W.)')
      expect(record['agent_sources'][0]['file_uri']).to eq('http://www.google.com')
    end

    it 'imports bioghist notes' do
      raw = convert(person_agent_1)

      record = raw.select { |r| r['jsonmodel_type'] == 'agent_person' }.first

      expect(record['notes'][0]['label']).to eq('Biographical note')
      expect(record['notes'][1]['label']).to eq('Administrative history')

      expect(record['notes'][0]['subnotes'][0]['jsonmodel_type']).to eq('note_abstract')
      expect(record['notes'][0]['subnotes'][0]['content']).to eq(['Biographical or historical data.'])
      expect(record['notes'][0]['subnotes'][1]['jsonmodel_type']).to eq('note_text')
      expect(record['notes'][0]['subnotes'][1]['content']).to eq('Expansion ...')

      expect(record['notes'][1]['label']).to eq('Administrative history')
    end
  end

  describe 'collection of agent records' do
    it 'imports all agent records in a collection of records' do
      records = convert(agent_collection).select { |r| r['jsonmodel_type'] == 'agent_person' }

      expect(records.count).to eq(3)
    end

    it 'imports each authorized name' do
      records = convert(agent_collection).select { |r| r['jsonmodel_type'] == 'agent_person' }

      expect(records[0]['names'][0]['authorized']).to eq(true)
      expect(records[0]['names'][0]['primary_name']).to eq('Roosevelt')
      expect(records[0]['names'][0]['rest_of_name']).to eq('Eleanor Butler')

      expect(records[1]['names'][0]['authorized']).to eq(true)
      expect(records[1]['names'][0]['primary_name']).to eq('Roosevelt')
      expect(records[1]['names'][0]['rest_of_name']).to eq('Eleanor')

      expect(records[2]['names'][0]['authorized']).to eq(true)
      expect(records[2]['names'][0]['primary_name']).to eq('Roosevelt')
      expect(records[2]['names'][0]['rest_of_name']).to eq('Anna')
    end

    it 'imports each parallel name to the correct agent' do
      records = convert(agent_collection).select { |r| r['jsonmodel_type'] == 'agent_person' }
      expect(records[0]['names'].count).to eq(2)
      expect(records[0]['names'][1]['primary_name']).to eq('Alexander')
      expect(records[0]['names'][1]['rest_of_name']).to eq('Eleanor Butler')

      expect(records[1]['names'].count).to eq(5)
      expect(records[1]['names'][1]['primary_name']).to eq('Roosevelt')
      expect(records[1]['names'][1]['rest_of_name']).to eq('Eleanor Roosevelt')
      expect(records[1]['names'][3]['primary_name']).to eq('Roosevelt')
      expect(records[1]['names'][3]['rest_of_name']).to eq('Franklin D.')

      expect(records[2]['names'].count).to eq(5)
      expect(records[2]['names'][2]['primary_name']).to eq('Boettiger')
      expect(records[2]['names'][2]['rest_of_name']).to eq('Anna Roosevelt')
      expect(records[2]['names'][4]['primary_name']).to eq('Halsted')
      expect(records[2]['names'][4]['rest_of_name']).to eq('Anna Roosevelt')
    end

    it 'imports record identifiers to the correct agent' do
      records = convert(agent_collection).select { |r| r['jsonmodel_type'] == 'agent_person' }

      expect(records[0]['agent_record_identifiers'].count).to eq(2)
      expect(records[0]['agent_record_identifiers'][0]['record_identifier']).to eq('n  97046493 ')
      expect(records[0]['agent_record_identifiers'][0]['primary_identifier']).to eq(true)
      expect(records[0]['agent_record_identifiers'][1]['record_identifier']).to eq('(DLC)n  97046493')
      expect(records[0]['agent_record_identifiers'][1]['primary_identifier']).to eq(false)

      expect(records[1]['agent_record_identifiers'].count).to eq(2)
      expect(records[1]['agent_record_identifiers'][0]['record_identifier']).to eq('n  79144645 ')
      expect(records[1]['agent_record_identifiers'][0]['primary_identifier']).to eq(true)
      expect(records[1]['agent_record_identifiers'][1]['record_identifier']).to eq('(OCoLC)oca00375794')
      expect(records[1]['agent_record_identifiers'][1]['primary_identifier']).to eq(false)

      expect(records[2]['agent_record_identifiers'].count).to eq(2)
      expect(records[2]['agent_record_identifiers'][0]['record_identifier']).to eq('n  81147297 ')
      expect(records[2]['agent_record_identifiers'][0]['primary_identifier']).to eq(true)
      expect(records[2]['agent_record_identifiers'][1]['record_identifier']).to eq('(OCoLC)oca00692063')
      expect(records[2]['agent_record_identifiers'][1]['primary_identifier']).to eq(false)
    end

    it 'imports record control language to the correct agent' do
      records = convert(agent_collection).select { |r| r['jsonmodel_type'] == 'agent_person' }

      expect(records[0]['agent_record_controls'][0]['language']).to be_nil
      expect(records[1]['agent_record_controls'][0]['language']).to eq('eng')
      expect(records[2]['agent_record_controls'][0]['language']).to eq('eng')
    end
  end
end
