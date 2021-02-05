# frozen_string_literal: true

require_relative 'export_spec_helper'

describe 'MARC Auth Export' do
  describe 'control tags' do
    it 'exports to leader' do
      r = create(:json_agent_person_full_subrec,
                 agent_record_identifiers: [
                   build(:agent_record_identifier, primary_identifier: true),
                   build(:agent_record_identifier, primary_identifier: false)
                 ])

      marc = get_marc_auth(r)
      expect(marc.xpath('//leader').to_s).to eq('<leader>00000nz  a2200000oi 4500</leader>')
    end

    it 'exports to controlfield 001' do
      r = create(:json_agent_person_full_subrec,
                 agent_record_identifiers: [
                   build(:agent_record_identifier, primary_identifier: true),
                   build(:agent_record_identifier, primary_identifier: false)
                 ])

      marc = get_marc_auth(r)
      expect(marc.xpath('//controlfield[@tag=001]').to_s).to match(/#{r["agent_record_identifiers"].first['record_identifier']}/)
    end

    it 'exports to controlfield 003' do
      r = create(:json_agent_person_full_subrec,
                 agent_record_identifiers: [
                   build(:agent_record_identifier, primary_identifier: true),
                   build(:agent_record_identifier, primary_identifier: false)
                 ])

      marc = get_marc_auth(r)

      expect(marc.xpath('//controlfield[@tag=003]').to_s).to match(/#{r["agent_record_controls"].first['maintenance_agency']}/)
    end

    it 'exports to controlfield 008' do
      r = create(:json_agent_person_full_subrec,
                 agent_record_identifiers: [
                   build(:agent_record_identifier, primary_identifier: true),
                   build(:agent_record_identifier, primary_identifier: false)
                 ])

      marc = get_marc_auth(r)

      expect(marc.xpath('//controlfield[@tag=008]').to_s).to match(/n|aznnnaabn           a/)
    end
  end

  describe 'identity and record control tags' do
    it 'exports to, and does not duplicate, 010' do
      r = create(:json_agent_person_full_subrec,
                 agent_record_identifiers: [
                   build(:agent_record_identifier, primary_identifier: true),
                   build(:agent_record_identifier, primary_identifier: false, identifier_type: 'loc'),
                   build(:agent_record_identifier, primary_identifier: false)
                 ])

      loc_ids = r['agent_record_identifiers'].select { |ari| ari['identifier_type'] == 'loc' }

      marc = get_marc_auth(r)

      expect(marc.xpath('//datafield[@tag=010]').count).to eq 1
      expect(marc.xpath('//datafield[@tag=010]').to_s).to match(/#{loc_ids.first['record_identifier']}/)
    end

    it 'exports to 016' do
      r = create(:json_agent_person_full_subrec,
                 agent_record_identifiers: [
                   build(:agent_record_identifier, primary_identifier: true, identifier_type: 'lac')
                 ])

      lac_ids = r['agent_record_identifiers'].select { |ari| ari['identifier_type'] == 'lac' }

      marc = get_marc_auth(r)

      expect(marc.xpath('//datafield[@tag=016]').to_s).to match(/#{lac_ids.first['record_identifier']}/)
    end

    it 'exports to 024 and can export multiple' do
      r = create(:json_agent_person_full_subrec,
                 agent_record_identifiers: [
                   build(:agent_record_identifier, primary_identifier: true, identifier_type: 'other_unmapped'),
                   build(:agent_record_identifier, primary_identifier: true, identifier_type: 'other_unmapped')
                 ])

      other_ids = r['agent_record_identifiers'].select { |ari| ari['identifier_type'] == 'other_unmapped' }

      marc = get_marc_auth(r)

      expect(marc.xpath('//datafield[@tag=024]').count).to eq 2
      expect(marc.xpath('//datafield[@tag=024]').to_s).to match(/#{other_ids.first['record_identifier']}/)
    end

    it 'exports to 035' do
      r = create(:json_agent_person_full_subrec,
                 agent_record_identifiers: [
                   build(:agent_record_identifier, primary_identifier: true, identifier_type: 'local')
                 ])

      local_ids = r['agent_record_identifiers'].select { |ari| ari['identifier_type'] == 'local' }

      marc = get_marc_auth(r)

      expect(marc.xpath('//datafield[@tag=035]').to_s).to match(/#{local_ids.first['record_identifier']}/)
    end

    it 'exports to 040' do
      r = create(:json_agent_person_full_subrec,
                 agent_record_identifiers: [
                   build(:agent_record_identifier, primary_identifier: true, identifier_type: 'local')
                 ])
      arc = r['agent_record_controls'].first
      acd = r['agent_conventions_declarations'].first

      marc = get_marc_auth(r)

      expect(marc.xpath('//datafield[@tag=040]').to_s).to match(/#{arc['maintenance_agency']}/)
      expect(marc.xpath('//datafield[@tag=040]').to_s).to match(/#{arc['language']}/)
      expect(marc.xpath('//datafield[@tag=040]').to_s).to match(/#{acd['name_rule']}/)
    end
  end

  describe 'agent_person' do
    before(:all) do
      as_test_user('admin') do
        @rec = create(:json_agent_person_full_subrec,
                      names: [
                        build(:json_name_person,
                              prefix: 'abcdefg'),
                        build(:json_name_person)
                      ])
      end
    end

    after(:all) do
      as_test_user('admin') do
        @rec.delete
      end
    end

    it 'maps authorized name to 100 tag' do
      marc = get_marc_auth(@rec)

      primary = @rec['names'].select { |n| n['authorized'] == true }.first
      expect(marc.xpath('//datafield[@tag=100]').to_s).to match(/#{primary['primary_name']}/)
      expect(marc.xpath('//datafield[@tag=100]').to_s).to match(/#{primary['number']}/)
      expect(marc.xpath('//datafield[@tag=100]').to_s).to match(/#{primary['title']}/)
      expect(marc.xpath('//datafield[@tag=100]').to_s).to match(/#{primary['dates']}/)
      expect(marc.xpath('//datafield[@tag=100]').to_s).to match(/#{primary['qualifier']}/)
      expect(marc.xpath('//datafield[@tag=100]').to_s).to match(/#{primary['fuller_form']}/)
    end

    it 'maps unauthorized name to 400 tag' do
      marc = get_marc_auth(@rec)

      not_primary = @rec['names'].select { |n| n['authorized'] == false }.first
      expect(marc.xpath('//datafield[@tag=400]').to_s).to match(/#{not_primary['primary_name']}/)
      expect(marc.xpath('//datafield[@tag=400]').to_s).to match(/#{not_primary['number']}/)
      expect(marc.xpath('//datafield[@tag=400]').to_s).to match(/#{not_primary['title']}/)
      expect(marc.xpath('//datafield[@tag=400]').to_s).to match(/#{not_primary['dates']}/)
      expect(marc.xpath('//datafield[@tag=400]').to_s).to match(/#{not_primary['qualifier']}/)
      expect(marc.xpath('//datafield[@tag=400]').to_s).to match(/#{not_primary['fuller_form']}/)
    end

    it 'exports agent_genders' do
      marc = get_marc_auth(@rec)

      expect(marc.xpath('//datafield[@tag=375]').to_s).to match(/not_specified/)
    end
  end

  describe 'agent_corporate_entity' do
    before(:all) do
      as_test_user('admin') do
        @rec = create(:json_agent_corporate_entity_full_subrec,
                      names: [
                        build(:json_name_corporate_entity, authorized: true),
                        build(:json_name_corporate_entity, authorized: false)
                      ])
      end
    end

    after(:all) do
      as_test_user('admin') do
        @rec.delete
      end
    end

    it 'maps authorized name to 110 tag' do
      marc = get_marc_auth(@rec)
      primary = @rec['names'].select { |n| n['authorized'] == true }.first

      expect(marc.xpath('//datafield[@tag=110]').to_s).to match(/#{primary['primary_name']}/)
      expect(marc.xpath('//datafield[@tag=110]').to_s).to match(/#{primary['number']}/)
      expect(marc.xpath('//datafield[@tag=110]').to_s).to match(/#{primary['subordinate_name_1']}/)
      expect(marc.xpath('//datafield[@tag=110]').to_s).to match(/#{primary['subordinate_name_2']}/)
      expect(marc.xpath('//datafield[@tag=110]').to_s).to match(/#{primary['dates']}/)
      expect(marc.xpath('//datafield[@tag=110]').to_s).to match(/#{primary['qualifier']}/)
      expect(marc.xpath('//datafield[@tag=110]').to_s).to match(/#{primary['location']}/)
    end

    it 'maps authorized name with conferernce meeting to 111 tag' do
      rec = create(:json_agent_corporate_entity_full_subrec,
                   names: [
                     build(:json_name_corporate_entity, authorized: true, conference_meeting: true),
                     build(:json_name_corporate_entity, authorized: false)
                   ])
      marc = get_marc_auth(rec)

      primary = rec['names'].select { |n| n['authorized'] == true }.first

      expect(marc.xpath('//datafield[@tag=111]').to_s).to match(/#{primary['primary_name']}/)
      expect(marc.xpath('//datafield[@tag=111]').to_s).to match(/#{primary['number']}/)
      expect(marc.xpath('//datafield[@tag=111]').to_s).to match(/#{primary['subordinate_name_1']}/)
      expect(marc.xpath('//datafield[@tag=111]').to_s).to match(/#{primary['subordinate_name_2']}/)
      expect(marc.xpath('//datafield[@tag=111]').to_s).to match(/#{primary['dates']}/)
      expect(marc.xpath('//datafield[@tag=111]').to_s).to match(/#{primary['qualifier']}/)
      expect(marc.xpath('//datafield[@tag=111]').to_s).to match(/#{primary['location']}/)
    end

    it 'maps unauthorized name to 410 tag' do
      marc = get_marc_auth(@rec)
      not_primary = @rec['names'].select { |n| n['authorized'] == false }.first
      expect(marc.xpath('//datafield[@tag=410]').to_s).to match(/#{not_primary['primary_name']}/)
      expect(marc.xpath('//datafield[@tag=410]').to_s).to match(/#{not_primary['number']}/)
      expect(marc.xpath('//datafield[@tag=410]').to_s).to match(/#{not_primary['subordinate_name_1']}/)
      expect(marc.xpath('//datafield[@tag=410]').to_s).to match(/#{not_primary['subordinate_name_2']}/)
      expect(marc.xpath('//datafield[@tag=410]').to_s).to match(/#{not_primary['dates']}/)
      expect(marc.xpath('//datafield[@tag=410]').to_s).to match(/#{not_primary['qualifier']}/)
      expect(marc.xpath('//datafield[@tag=410]').to_s).to match(/#{not_primary['location']}/)
    end

    it 'maps unauthorized name with conferernce meeting to 411 tag' do
      rec = create(:json_agent_corporate_entity_full_subrec,
                   names: [
                     build(:json_name_corporate_entity, authorized: true),
                     build(:json_name_corporate_entity, authorized: false, conference_meeting: true)
                   ])

      marc = get_marc_auth(rec)
      not_primary = rec['names'].select { |n| n['authorized'] == false }.first
      expect(marc.xpath('//datafield[@tag=411]').to_s).to match(/#{not_primary['primary_name']}/)
      expect(marc.xpath('//datafield[@tag=411]').to_s).to match(/#{not_primary['number']}/)
      expect(marc.xpath('//datafield[@tag=411]').to_s).to match(/#{not_primary['subordinate_name_1']}/)
      expect(marc.xpath('//datafield[@tag=411]').to_s).to match(/#{not_primary['subordinate_name_2']}/)
      expect(marc.xpath('//datafield[@tag=411]').to_s).to match(/#{not_primary['dates']}/)
      expect(marc.xpath('//datafield[@tag=411]').to_s).to match(/#{not_primary['qualifier']}/)
      expect(marc.xpath('//datafield[@tag=411]').to_s).to match(/#{not_primary['location']}/)
    end
  end

  describe 'agent_family' do
    before(:all) do
      as_test_user('admin') do
        @rec = create(:json_agent_family_full_subrec,
                      names: [
                        build(:json_name_family,
                              prefix: 'abcdefg'),
                        build(:json_name_family, authorized: false)
                      ])
      end
    end

    after(:all) do
      as_test_user('admin') do
        @rec.delete
      end
    end

    it 'maps authorized name to 100 tag' do
      marc = get_marc_auth(@rec)

      primary = @rec['names'].select { |n| n['authorized'] == true }.first
      expect(marc.xpath('//datafield[@tag=100]').to_s).to match(/#{primary['family_name']}/)
      expect(marc.xpath('//datafield[@tag=100]').to_s).to match(/#{primary['dates']}/)
      expect(marc.xpath('//datafield[@tag=100]').to_s).to match(/#{primary['qualifier']}/)
    end

    it 'maps unauthorized name to 400 tag' do
      marc = get_marc_auth(@rec)
      primary = @rec['names'].select { |n| n['authorized'] == true }.first
      expect(marc.xpath('//datafield[@tag=100]').to_s).to match(/#{primary['family_name']}/)
      expect(marc.xpath('//datafield[@tag=100]').to_s).to match(/#{primary['dates']}/)
      expect(marc.xpath('//datafield[@tag=100]').to_s).to match(/#{primary['qualifier']}/)
    end
  end

  describe 'descriptive subrecords' do
    describe 'subject linked subrecords' do
      it 'exports agent_places' do
        rec = create(:json_agent_person_full_subrec,
                     agent_places: [build(:json_agent_place), build(:json_agent_place)])
        marc = get_marc_auth(rec)
        # check that we exported both place subjects (this applies for any subject subrecord)
        expect(marc.xpath('//datafield[@tag=370]').count).to eq 2
        expect(marc.xpath('//datafield[@tag=370]').to_s).to_not be_nil
      end

      it 'exports agent_occupations' do
        rec = create(:json_agent_person_full_subrec)
        marc = get_marc_auth(rec)
        expect(marc.xpath('//datafield[@tag=374]').to_s).to_not be_nil
      end

      it 'exports agent_functions' do
        rec = create(:json_agent_person_full_subrec)
        marc = get_marc_auth(rec)
        expect(marc.xpath('//datafield[@tag=372]').to_s).to_not be_nil
      end

      it 'exports agent_topics' do
        rec = create(:json_agent_person_full_subrec)
        marc = get_marc_auth(rec)
        expect(marc.xpath('//datafield[@tag=372]').to_s).to_not be_nil
      end
    end

    describe 'used_languages' do
      it 'exports used_languages' do
        rec = create(:json_agent_person_full_subrec)
        marc = get_marc_auth(rec)
        expect(marc.xpath('//datafield[@tag=372]').to_s).to_not be_nil
      end
    end
  end

  describe 'dates of existence' do
    it 'creates a 046 tag for march date of existence' do
      rec = create(:json_agent_person_full_subrec,
                   dates_of_existence: [
                     build(:json_structured_date_label),
                     build(:json_structured_date_label),
                     build(:json_structured_date_label_range)
                   ])
      marc = get_marc_auth(rec)

      expect(marc.xpath('//datafield[@tag=046]').to_s).to_not be_nil
    end

    it 'does not create a 046 tag if date of existence does not have a standardized date' do
      sdl = build(:json_structured_date_label)
      sdl['structured_date_single']['date_standardized'] = nil

      rec = create(:json_agent_person_full_subrec, dates_of_existence: [sdl])

      marc = get_marc_auth(rec)

      expect(marc.xpath('//datafield[@tag=046]//subfield[@code=f]').to_s).to eq('')
    end
  end

  describe 'bioghist notes' do
    before(:all) do
      as_test_user('admin') do
        subnotes = [
          :note_abstract,
          :note_text
        ]

        @rec = create(:json_agent_person,
                      notes: [build(:json_note_bioghist,
                                    subnotes: subnotes.map do |type|
                                      build("json_#{type}".intern,
                                            publish: true)
                                    end,
                                    publish: true)])
      end
    end

    it 'creates a 678 tag for bioghist note' do
      marc = get_marc_auth(@rec)
      expect(marc.xpath('//datafield[@tag=678]').to_s).to_not be_nil
    end

    it "creates an 'a' subfield tag for abstract subnote" do
      marc = get_marc_auth(@rec)
      expect(marc.xpath("//datafield[@tag=678]/subnote[@code='a']").to_s).to_not be_nil
    end

    it "creates an 'b' subfield tag for content subnote" do
      marc = get_marc_auth(@rec)
      expect(marc.xpath("//datafield[@tag=678]/subnote[@code='b']").to_s).to_not be_nil
    end
  end

  describe 'agent relationships' do
    it 'maps related agents' do
      rec = create(:json_agent_person_full_subrec)
      relationship = JSONModel(:agent_relationship_parentchild).new
      relationship.relator = 'is_child_of'
      relationship.ref = rec.uri
      create(:json_agent_person,
             related_agents: [relationship.to_hash])
      marc = get_marc_auth(rec)
      expect(marc.xpath('//datafield[@tag=500]').to_s).to_not be_nil
    end
  end
end
