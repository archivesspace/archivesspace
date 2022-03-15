# frozen_string_literal: true

require_relative 'export_spec_helper'

describe 'EAC Export' do
  describe 'control tags' do
    it 'exports agent_record_identifiers as recordId and otherRecordId' do
      r = create(:json_agent_person_full_subrec,
                 agent_record_identifiers: [
                   build(:agent_record_identifier, primary_identifier: true),
                   build(:agent_record_identifier, primary_identifier: false)
                 ])

      eac = get_eac(r)
      expect(eac).to have_tag('control/recordId')
      expect(eac).to have_tag('control/otherRecordId')
    end

    #ANW-1266: for this test, the factory value for agent_record_control['maintenance_status'] is expected not to be 'revised_corrected', as that is a special case handled in the next test.
    it 'agent_record_control to control tags' do
      r = create(:json_agent_person_full_subrec)
      arc = r['agent_record_controls'].first
      AppConfig[:export_eac_agency_code] = true
      eac = get_eac(r)

      maint_status_value = case I18n.t("enumerations.maintenance_status.#{arc['maintenance_status']}")
                           when "New"
                             "new"
                           when "Upgraded"
                             "revised"
                           when "Revised/Corrected"
                             "revised"
                           when "Derived"
                             "derived"
                           when "Deleted"
                             "deleted"
                           when "Cancelled/Obsolete"
                             "cancelled"
                           when "Deleted-Split"
                             "deletedSplit"
                           when "Deleted-Replaced"
                             "deletedReplaced"
                           when "Deleted-Merged"
                             "deletedMerged"
                           end

      expect(eac).to have_tag 'control/maintenanceStatus' => maint_status_value
      expect(eac).to have_tag 'control/publicationStatus' => arc['publication_status']
      expect(eac).to have_tag 'control/maintenanceAgency/agencyName' => arc['agency_name']
      expect(eac).to have_tag 'control/maintenanceAgency/agencyCode' => arc['maintenance_agency']
      expect(eac).to have_tag 'control/maintenanceAgency/descriptiveNote/p' => arc['maintenance_agency_note']
      expect(eac).to have_tag 'control/languageDeclaration/language' => I18n.t("enumerations.language_iso639_2.#{arc['language']}")
      expect(eac).to have_tag 'control/languageDeclaration/descriptiveNote/p' => arc['language_note']
    end

    it 'exports maintenanceStatus tag value as Revised instead of Revised/Corrected' do

      r = create(:json_agent_person_full_subrec,
        :agent_record_controls => [ build(:agent_record_control,
          :maintenance_status => "revised_corrected")
        ])

      arc = r['agent_record_controls'].first
      AppConfig[:export_eac_agency_code] = true
      eac = get_eac(r)

      expect(eac).to have_tag 'control/maintenanceStatus' => "revised"
    end

    it 'does not export agency_code in agent_record_controls if config option not set' do
      r = create(:json_agent_person_full_subrec)
      AppConfig[:export_eac_agency_code] = false
      eac = get_eac(r)
      expect(eac).to_not have_tag 'control/maintenanceAgency/agencyCode'
    end

    it 'agent_conventions_dec to conventionDeclaration tag' do
      r = create(:json_agent_person_full_subrec)
      cd = r['agent_conventions_declarations'].first
      eac = get_eac(r)

      expect(eac).to have_tag 'control/conventionDeclaration/abbreviation' => cd['name_rule']
      expect(eac).to have_tag 'control/conventionDeclaration/citation' => cd['citation']
      expect(eac).to have_tag 'control/conventionDeclaration/citation',
                              { 'lastDateTimeVerified' => DateTime.parse(cd['last_verified_date']).iso8601 }
      expect(eac).to have_tag 'control/conventionDeclaration/descriptiveNote/p' => cd['descriptive_note']
    end

    it 'agent_maint_history to maintenanceHistory tag' do
      r = create(:json_agent_person_full_subrec)
      mh = r['agent_maintenance_histories'].first
      eac = get_eac(r)

      expect(eac).to have_tag 'control/maintenanceHistory/maintenanceEvent/eventType' => mh['maintenance_event_type']
      expect(eac).to have_tag 'control/maintenanceHistory/maintenanceEvent/eventDateTime',
                              { 'standardDateTime' => DateTime.parse(mh['event_date']).iso8601 }
      expect(eac).to have_tag 'control/maintenanceHistory/maintenanceEvent/agentType' => mh['maintenance_agent_type']
      expect(eac).to have_tag 'control/maintenanceHistory/maintenanceEvent/eventDescription' => mh['descriptive_note']
      expect(eac).to have_tag 'control/maintenanceHistory/maintenanceEvent/agent' => mh['agent']
    end

    it 'agent_sources to sources tag' do
      r = create(:json_agent_person_full_subrec)
      as = r['agent_sources'].first
      eac = get_eac(r)

      expect(eac).to have_tag 'control/sources/source'
      expect(eac).to have_tag 'control/sources/source/sourceEntry' => as['source_entry']
      expect(eac).to have_tag 'control/sources/source/descriptiveNote/p' => as['descriptive_note']
    end
  end

  describe 'identity tags' do
    it 'agent_identifiers to entityId tag' do
      r = create(:json_agent_person_full_subrec)
      ad = r['agent_identifiers'].first
      eac = get_eac(r)

      expect(eac).to have_tag 'identity/entityId' => ad['entity_identifier']
    end
  end

  describe 'nameEntryParallel tag' do
    it 'wraps names with parallel names in a nameEntryParallel tag' do
      r = create(:json_agent_person_full_subrec,
                 names: [build(:json_name_person,
                               parallel_names: [build(:json_parallel_name_person)])])

      eac = get_eac(r)
      n = r['names'].first

      expect(eac).to have_tag 'identity/nameEntryParallel/nameEntry/part' => n['primary_name']
      expect(eac).to have_tag 'identity/nameEntryParallel/useDates'
      expect(eac).to have_tag 'identity/nameEntryParallel/nameEntry[1]/preferredForm'
      expect(eac).to have_tag 'identity/nameEntryParallel/nameEntry[1]/authorizedForm'
      expect(eac).to have_tag 'identity/nameEntryParallel/nameEntry[2]/part'
      expect(eac).not_to have_tag 'identity/nameEntryParallel/nameEntry[2]/preferredForm'
      expect(eac).not_to have_tag 'identity/nameEntryParallel/nameEntry[2]/authorizedForm'
      expect(eac).not_to have_tag 'identity/nameEntryParallel/nameEntry/useDates'
    end
  end

  describe 'agent_person' do
    before(:all) do
      as_test_user('admin', true) do
        @rec = create(:json_agent_person_full_subrec,
                      names: [
                        build(:json_name_person,
                              prefix: 'abcdefg'),
                        build(:json_name_person)
                      ])

        @eac = get_eac(@rec)
        raise Sequel::Rollback
      end
    end

    it 'exports EAC with the correct namespaces' do
      expect(@eac).to have_namespaces({
                                        'xmlns' => 'urn:isbn:1-931666-33-4',
                                        'xmlns:html' => 'http://www.w3.org/1999/xhtml',
                                        'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
                                        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance'
                                      })
    end

    it 'maps name.source to authorizedForm' do
      source1 = @rec.names[0]['source']
      expect(@eac).to have_tag('nameEntry[1]/authorizedForm' => source1)
    end

    it "maps name.prefix to nameEntry/part[@localType='prefix']" do
      val = @rec.names[0]['prefix']
      tag = "nameEntry[1]/part[@localType='prefix']"
      if val
        expect(@eac).to have_tag(tag => val)
      else
        expect(@eac).not_to have_tag(tag)
      end
    end

    it "maps name.title to nameEntry/part[@localType='title']" do
      expect(@rec.names[0]['title']).to_not be_nil
      val = @rec.names[0]['title']

      tag = "nameEntry[1]/part[@localType='title']"
      expect(@eac).to have_tag(tag => val)
    end

    it "maps name.primary_name to nameEntry/part[@localType='surname']" do
      val = @rec.names[0]['primary_name']
      tag = "nameEntry[1]/part[@localType='surname']"
      expect(@eac).to have_tag(tag => val)
    end

    it "maps name.rest_of_name to nameEntry/part[@localType='forename']" do
      val = @rec.names[0]['rest_of_name']
      tag = "nameEntry[1]/part[@localType='forename']"
      if val
        expect(@eac).to have_tag(tag => val)
      else
        expect(@eac).not_to have_tag(tag)
      end
    end

    it "maps name.suffix to nameEntry/part[@localType='suffix']" do
      val = @rec.names[0]['suffix']
      tag = "nameEntry[1]/part[@localType='suffix']"
      if val
        expect(@eac).to have_tag(tag => val)
      else
        expect(@eac).not_to have_tag(tag)
      end
    end

    it "maps name.number to nameEntry/part[@localType='numeration']" do
      val = @rec.names[0]['number']
      tag = "nameEntry[1]/part[@localType='numeration']"
      expect(@eac).to have_tag(tag => val)
    end

    it "maps name.fuller_form to nameEntry/part[@localType='fullerForm']" do
      val = @rec.names[0]['fuller_form']
      tag = "nameEntry[1]/part[@localType='fuller_form']"
      expect(@eac).to have_tag(tag => val)
    end

    it "maps name qualifier to nameEntry/part[@localType='qualifier']" do
      val = @rec.names[0]['qualifier']
      tag = "nameEntry[1]/part[@localType='qualifier']"
      expect(@eac).to have_tag(tag => val)
    end

    it 'maps agent_person records to EAC docs with entityType = person' do
      expect(@eac).to have_tag('entityType' => 'person')
    end

    it 'exports agent_genders' do
      expect(@eac).to have_tag("/description/localDescriptions/localDescription[@localType='gender']/term")
      expect(@eac).to have_tag("/description/localDescriptions/localDescription[@localType='gender']/date")
      expect(@eac).to have_tag("/description/localDescriptions/localDescription[@localType='gender']/descriptiveNote/p")
    end
  end

  describe 'agent_corporate_entity' do
    before(:all) do
      as_test_user('admin', true) do
        date1 = build(:json_structured_date_label_range)
        date2 = build(:json_structured_date_label_range)
        date3 = build(:json_structured_date_label)
        note1 = build(:json_note_general_context)
        note2 = build(:json_note_mandate)
        note3 = build(:json_note_legal_status)
        note4 = build(:json_note_structure_or_genealogy)

        @rec = create(:json_agent_corporate_entity,
                      names: [
                        build(:json_name_corporate_entity,
                              use_dates: [
                                date1,
                                date2,
                                date3
                              ]),
                        build(:json_name_corporate_entity)
                      ],
                      notes: [
                        note1,
                        note2,
                        note3,
                        note4
                      ])

        @eac = get_eac(@rec)
        raise Sequel::Rollback
      end
    end

    it "maps name.primary_name to nameEntry/part[@localType='primary_name']" do
      val = @rec.names[0]['primary_name']
      tag = "nameEntry[1]/part[@localType='primary_name']"
      expect(@eac).to have_tag(tag => val)
    end

    it "maps name.subordinate_name_1 to nameEntry/part[@localType='subordinate_name_1']" do
      val = @rec.names[0]['subordinate_name_1']
      tag = "nameEntry[1]/part[@localType='subordinate_name_1']"
      expect(@eac).to have_tag(tag => val)
    end

    it "maps name.subordinate_name_2 to nameEntry/part[@localType='subordinate_name_2']" do
      val = @rec.names[0]['subordinate_name_2']
      tag = "nameEntry[1]/part[@localType='subordinate_name_2']"
      expect(@eac).to have_tag(tag => val)
    end

    it "maps name.number to nameEntry/part[@localType='numeration']" do
      val = @rec.names[0]['number']
      tag = "nameEntry[1]/part[@localType='numeration']"
      expect(@eac).to have_tag(tag => val)
    end

    it "maps name qualifier to nameEntry/part[@localType='qualifier']" do
      val = @rec.names[0]['qualifier']
      tag = "nameEntry[1]/part[@localType='qualifier']"
      expect(@eac).to have_tag(tag => val)
    end

    it 'maps each name.use_dates[] to a useDates tag' do
      expect(@eac).to have_tag('nameEntry[1]/useDates')
    end

    it 'creates a from- and to-Date for range dates' do
      d = @rec.names[0]['use_dates'][0]['structured_date_range']
      expect(@eac).to have_tag("nameEntry[1]/useDates/dateRange[1]/fromDate[@standardDate=\"#{d['begin_date_standardized']}\"]" => (d['begin_date_expression']).to_s)
      expect(@eac).to have_tag("nameEntry[1]/useDates/dateRange[1]/toDate[@standardDate=\"#{d['end_date_standardized']}\"]" => (d['end_date_expression']).to_s)
    end

    it "creates a date tag for 'single' dates" do
      d = @rec.names[0]['use_dates'][2]['structured_date_single']
      expect(@eac).to have_tag('nameEntry[1]/useDates/date' => d['date_expression'])
    end

    it 'maps general context notes to /generalContext' do
      n = @rec['notes'][0]['subnotes'][1]['content']
      expect(@eac).to have_tag('description/generalContext/p' => n)
    end

    it 'maps mandate notes to /mandate' do
      n = @rec['notes'][1]['subnotes'][0]['content']
      expect(@eac).to have_tag('description/mandate/p' => n)
    end

    it 'maps legal status notes to /legalStatus' do
      n = @rec['notes'][2]['subnotes'][0]['content']
      expect(@eac).to have_tag('description/legalStatus/p' => n)
    end

    it 'maps structure/genealogy notes to /structureOrGenealogy' do
      n = @rec['notes'][3]['subnotes'][0]['content']
      expect(@eac).to have_tag('description/structureOrGenealogy/p' => n)
    end
  end

  describe 'agent_family' do
    before(:all) do
      as_test_user('admin', true) do
        @rec = create(:json_agent_family,
                      names: [
                        build(:json_name_family),
                        build(:json_name_family)
                      ])

        @eac = get_eac(@rec)
        raise Sequel::Rollback
      end
    end

    it "maps name.prefix to nameEntry/part[@localType='prefix']" do
      val = @rec.names[0]['prefix']
      tag = "nameEntry[1]/part[@localType='prefix']"
      if val
        expect(@eac).to have_tag(tag => val)
      else
        expect(@eac).not_to have_tag(tag)
      end
    end

    it "maps name.family_name to nameEntry/part[@localType='surname']" do
      val = @rec.names[0]['family_name']
      tag = "nameEntry[1]/part[@localType='surname']"
      if val
        expect(@eac).to have_tag(tag => val)
      else
        expect(@eac).not_to have_tag(tag)
      end
    end
  end

  describe 'alternative set subrecords' do
    before(:all) do
      as_test_user('admin', true) do
        @rec = create(:json_agent_person_full_subrec)
        @eac = get_eac(@rec)
        raise Sequel::Rollback
      end
    end

    it 'imports agent alternative set' do
      expect(@eac).to have_tag('cpfDescription/alternativeSet/setComponent[@xlink:actuate]')
      expect(@eac).to have_tag('cpfDescription/alternativeSet/setComponent[@xlink:arcrole]')
      expect(@eac).to have_tag('cpfDescription/alternativeSet/setComponent[@xlink:href]')
      expect(@eac).to have_tag('cpfDescription/alternativeSet/setComponent[@xlink:role]')
      expect(@eac).to have_tag('cpfDescription/alternativeSet/setComponent[@xlink:show]')
      expect(@eac).to have_tag('cpfDescription/alternativeSet/setComponent[@xlink:title]')
      expect(@eac).to have_tag('cpfDescription/alternativeSet/setComponent/componentEntry')
      expect(@eac).to have_tag('cpfDescription/alternativeSet/setComponent/descriptiveNote/p')
    end
  end

  describe 'subject linked subrecords' do
    before(:all) do
      as_test_user('admin', true) do
        @rec = create(:json_agent_person_full_subrec)
        @eac = get_eac(@rec)
        raise Sequel::Rollback
      end
    end

    it 'exports agent_places' do
      expect(@eac).to have_tag('description/places/place/placeRole')
      expect(@eac).to have_tag('description/places/place/placeEntry')
      expect(@eac).to have_tag('description/places/place/date')
      expect(@eac).to have_tag('description/places/place/descriptiveNote/p')
    end

    it 'exports agent_occupations' do
      expect(@eac).to have_tag('description/occupations/occupation/term')
      expect(@eac).to have_tag('description/occupations/occupation/date')
      expect(@eac).to have_tag('description/occupations/occupation/descriptiveNote/p')
      expect(@eac).to have_tag('description/occupations/occupation/placeEntry')
    end

    it 'exports agent_functions' do
      expect(@eac).to have_tag('description/functions/function/term')
      expect(@eac).to have_tag('description/functions/function/date')
      expect(@eac).to have_tag('description/functions/function/descriptiveNote/p')
      expect(@eac).to have_tag('description/functions/function/placeEntry')
    end

    it 'exports agent_topics' do
      expect(@eac).to have_tag("description/localDescriptions/localDescription[@localType='associatedSubject']/term")
      expect(@eac).to have_tag("description/localDescriptions/localDescription[@localType='associatedSubject']/date")
      expect(@eac).to have_tag("description/localDescriptions/localDescription[@localType='associatedSubject']/descriptiveNote/p")
      expect(@eac).to have_tag("description/localDescriptions/localDescription[@localType='associatedSubject']/placeEntry")
    end
  end

  describe 'used_languages' do
    before(:all) do
      as_test_user('admin', true) do
        @rec = create(:json_agent_person_full_subrec)
        @eac = get_eac(@rec)
        raise Sequel::Rollback
      end
    end

    it 'exports used_languages' do
      expect(@eac).to have_tag('description/languagesUsed/languageUsed/language')
      expect(@eac).to have_tag('description/languagesUsed/languageUsed/script')
      expect(@eac).to have_tag('description/languagesUsed/languageUsed/descriptiveNote/p')
    end
  end

  describe 'dates of existence' do
    before(:all) do
      as_test_user('admin', true) do
        @rec = create(:json_agent_person_full_subrec,
                      dates_of_existence: [
                        build(:json_structured_date_label),
                        build(:json_structured_date_label),
                        build(:json_structured_date_label_range)
                      ])
        @eac = get_eac(@rec)
        raise Sequel::Rollback
      end
    end

    it 'creates an existDates/date tag for each date of existence' do
      expect(@eac).to have_tag('description/existDates/date[1]')
      expect(@eac).to have_tag('description/existDates/date[2]')
      expect(@eac).to have_tag('description/existDates/dateRange')
    end

    it 'maps date.expression to date' do
      expect(@eac).to have_tag('description/existDates/date[1]' =>
                           @rec.dates_of_existence[0]['structured_date_single']['date_expression'])
    end

    it 'maps date.begin_date_expression to fromDate' do
      expect(@eac).to have_tag("existDates/dateRange/fromDate[@standardDate=\"#{@rec.dates_of_existence[2]['structured_date_range']['begin_date_standardized']}\"]" =>
                           @rec.dates_of_existence[2]['structured_date_range']['begin_date_expression'])
    end

    it 'maps date.end_date_expression to toDate' do
      expect(@eac).to have_tag("existDates/dateRange/toDate[@standardDate=\"#{@rec.dates_of_existence[2]['structured_date_range']['end_date_standardized']}\"]" =>
                           @rec.dates_of_existence[2]['structured_date_range']['end_date_expression'])
    end

    it 'maps date.standardized_date_type to correct attribute when a standardized_date is present for single dates' do
      sds1 = build(:json_structured_date_single, {
        :date_standardized_type => 'not_before'
      })

      sds2 = build(:json_structured_date_single, {
        :date_standardized_type => 'not_after'
      })

      sds3 = build(:json_structured_date_single, {
        :date_standardized_type => 'standard'
      })


      rec = create(:json_agent_person_full_subrec,
                    dates_of_existence: [
                      build(:json_structured_date_label, {
                        :structured_date_single => sds1
                      }),

                      build(:json_structured_date_label, {
                        :structured_date_single => sds2
                      }),

                      build(:json_structured_date_label, {
                        :structured_date_single => sds3
                      })
                    ])

      eac = get_eac(rec)

      std_date1 = rec.dates_of_existence[0]['structured_date_single']['date_standardized']
      std_date2 = rec.dates_of_existence[1]['structured_date_single']['date_standardized']
      std_date3 = rec.dates_of_existence[2]['structured_date_single']['date_standardized']

      expect(eac).to have_tag("description/existDates/date[@notBefore=\"#{std_date1}\"]" => rec.dates_of_existence[0]['structured_date_single']['date_expression'])
      expect(eac).to have_tag("description/existDates/date[@notAfter=\"#{std_date2}\"]" => rec.dates_of_existence[0]['structured_date_single']['date_expression'])
      expect(eac).to have_tag("description/existDates/date[@standardDate=\"#{std_date3}\"]" => rec.dates_of_existence[0]['structured_date_single']['date_expression'])
    end

    it "maps date.standardized_date to inner text when date expression is not defined" do

      sds = build(:json_structured_date_single, {
        :date_standardized_type => "not_before",
        :date_expression        => nil
      })

      rec = create(:json_agent_person_full_subrec,
                    dates_of_existence: [
                      build(:json_structured_date_label, {
                        :structured_date_single => sds
                      }
                    )])

      eac = get_eac(rec)
      std_date = rec.dates_of_existence[0]['structured_date_single']['date_standardized']

      expect(eac).to have_tag("description/existDates/date[@notBefore=\"#{std_date}\"]" => rec.dates_of_existence[0]['structured_date_single']['date_standardized'])
    end

    it 'maps date.standardized_date_type to correct attribute when a standardized_date is present for ranged dates' do

      sds1 = build(:json_structured_date_range, {
        :begin_date_standardized_type => 'not_before',
        :end_date_standardized_type => 'not_after'
      })

      sds2 = build(:json_structured_date_range, {
        :begin_date_standardized_type => 'not_before',
        :end_date_standardized_type => 'standard'
      })

      rec = create(:json_agent_person_full_subrec,
                    dates_of_existence: [
                      build(:json_structured_date_label_range, {
                        :structured_date_range => sds1,
                      }),
                      build(:json_structured_date_label_range, {
                        :structured_date_range => sds2,
                      })
                    ])

      eac = get_eac(rec)
      std_date1 = rec.dates_of_existence[0]['structured_date_range']['begin_date_standardized']
      std_date2 = rec.dates_of_existence[0]['structured_date_range']['end_date_standardized']
      std_date3 = rec.dates_of_existence[1]['structured_date_range']['end_date_standardized']

      expect(eac).to have_tag("description/existDates/dateRange/fromDate[@notBefore=\"#{std_date1}\"]" => rec.dates_of_existence[0]['structured_date_range']['begin_date_expression'])
      expect(eac).to have_tag("description/existDates/dateRange/toDate[@notAfter=\"#{std_date2}\"]" => rec.dates_of_existence[0]['structured_date_range']['end_date_expression'])
      expect(eac).to have_tag("description/existDates/dateRange/toDate[@standardDate=\"#{std_date3}\"]" => rec.dates_of_existence[0]['structured_date_range']['end_date_expression'])
    end

    it "maps date.standardized_date to inner text when date expression is not defined for ranged dates" do

      sds = build(:json_structured_date_range, {
        :begin_date_expression => nil,
        :end_date_expression   => nil
      })

      rec = create(:json_agent_person_full_subrec,
                    dates_of_existence: [
                      build(:json_structured_date_label_range, {
                        :structured_date_range => sds
                      }
                    )])

      eac = get_eac(rec)

      std_date_begin = rec.dates_of_existence[0]['structured_date_range']['begin_date_standardized']
      std_date_end = rec.dates_of_existence[0]['structured_date_range']['end_date_standardized']

      expect(eac).to have_tag("description/existDates/dateRange/fromDate" => std_date_begin)
      expect(eac).to have_tag("description/existDates/dateRange/toDate" => std_date_end)
    end


  end

  describe 'biographical / historical notes' do
    before(:all) do
      as_test_user('admin', true) do
        subnotes = [
          :note_abstract,
          :note_chronology,
          :note_citation,
          :note_orderedlist,
          :note_definedlist,
          :note_text,
          :note_outline
        ]

        @rec = create(:json_agent_person,
                      notes: [build(:json_note_bioghist,
                                    subnotes: subnotes.map do |type|
                                      build("json_#{type}".intern,
                                            publish: true)
                                    end,
                                    publish: true)])
        @eac = get_eac(@rec)

        @subnotes = Hash[subnotes.map { |type| [type, get_subnotes_by_type(@rec.notes[0], type.to_s)[0]] }]
        raise Sequel::Rollback
      end
    end

    it 'creates a biogHist tag for each note' do
      rec = create(:json_agent_person,
                   notes: [1, 2].map { build(:json_note_bioghist, publish: true) })
      eac = get_eac(rec)

      expect(eac).to have_tag('biogHist[2]')
    end

    it 'ignores un-published notes' do
      pending 'decision'
      rec = create(:json_agent_person,
                   notes: [build(:json_note_bioghist,
                                 publish: false)])

      eac = get_eac(rec)

      expect(eac).not_to have_tag('biogHist')
    end

    it "maps 'abstract' subnotes to abstract tags" do
      expect(@eac).to have_tag('biogHist/abstract' =>
                           @subnotes[:note_abstract]['content'].join('--'))
    end

    it "maps 'citation' subnotes to 'citation' tags" do
      xlink_values = @subnotes[:note_citation]['xlink']
      citation_text = @subnotes[:note_citation]['content'].join('--')

      expect(@eac).to have_tag("biogHist/citation[@xlink:actuate=\"#{xlink_values['actuate']}\"]")
      expect(@eac).to have_tag("biogHist/citation[@xlink:arcrole='#{xlink_values['arcrole']}']")
      expect(@eac).to have_tag("biogHist/citation[@xlink:href='#{xlink_values['href']}']")
      expect(@eac).to have_tag("biogHist/citation[@xlink:role='#{xlink_values['role']}']")
      expect(@eac).to have_tag("biogHist/citation[@xlink:show='#{xlink_values['show']}']")
      expect(@eac).to have_tag("biogHist/citation[@xlink:title='#{xlink_values['title']}']")

      expect(@eac).to have_tag('biogHist/citation' => citation_text)
    end

    it "maps 'definedlist' subnotes to 'list[@localType='defined']' tags" do
      list_items = @subnotes[:note_definedlist]['items']

      expect(@eac).to have_tag("biogHist/list[@localType='defined']/item[#{list_items.count}]")
      expect(@eac).to have_tag(
        "biogHist/list[@localType='defined']",
        { 'localType' => 'defined' }
      )
      expect(@eac).not_to have_tag("biogHist/list[@localType='defined']/item[#{list_items.count + 1}]")
      expect(@eac).to have_tag("biogHist/list/item[@localType='#{list_items.last['label']}']" => list_items.last['value'])
    end

    it "maps 'orderedlist' subnotes to 'list[@localType='ordered']' tags" do
      list_items = @subnotes[:note_orderedlist]['items']
      enumeration = @subnotes[:note_orderedlist]['enumeration']

      expect(@eac).to have_tag("biogHist/list[@localType='ordered']/item[#{list_items.count}]")
      expect(@eac).to have_tag(
        "biogHist/list[@localType='ordered']",
        { 'localType' => 'ordered' }
      )
      expect(@eac).not_to have_tag("biogHist/list[@localType='ordered']/item[#{list_items.count + 1}]")
      expect(@eac).to have_tag("biogHist/list/item[@localType='#{enumeration}']" => list_items.last)
    end

    it "maps 'chronology' subnotes to 'chronList' tags" do
      chron_title = @subnotes[:note_chronology]['title']

      if chron_title
        expect(@eac).to have_tag("biogHist/chronList[@localType='#{chron_title}']")
      else
        expect(@eac).not_to have_tag('biogHist/chronList[@localType]')
        expect(@eac).to have_tag('biogHist/chronList')
      end
    end

    it "maps every 'event' of every 'item' in a 'chronology' to a 'chronitem' tag" do
      events = @subnotes[:note_chronology]['items'].map { |i| i['events'].map { |e| [i['event_date'], e] } }.flatten(1)

      expect(@eac).to have_tag("chronList/chronItem[#{events.count}]")
      expect(@eac).not_to have_tag("chronList/chronItem[#{events.count + 1}]")
    end

    it "maps 'event_date' of an 'item' to each 'chronItem/@standardDate'" do
      events = @subnotes[:note_chronology]['items'].map { |i| i['events'].map { |e| [i['event_date'], e] } }.flatten(1)

      events.each do |event| # date, event pair
        if event[0]&.length
          expect(@eac).to have_tag("chronList/chronItem/date[@standardDate='#{event[0]}']" => event[0])
          expect(@eac).to have_tag("chronList/chronItem/date[@standardDate='#{event[0]}']", { 'standardDate' => event[0] })
        else
          expect(@eac).to have_tag('chronList/chronItem/event' => event[1])
          expect(@eac).not_to have_tag('chronList/chronItem[@standardDate]/event' => event[1])
        end
      end
    end

    it "maps 'outline' subnotes to 'outline' tags" do
      rec = create(:json_agent_person,
                   notes: [build(:json_note_bioghist, publish: true,
                                                      subnotes: [build(:json_note_outline,
                                                                       levels: (0..rand(3)).map do
                                                                                 build(:json_note_outline_level,
                                                                                       items: (0..rand(3)).map { [true, false].sample ? build(:json_note_outline_level) : generate(:alphanumstr) })
                                                                               end),
                                                                 build(:json_note_text)])])
      eac = get_eac(rec)

      outline = get_subnotes_by_type(rec.notes[0], 'note_outline')[0]
      expect(eac).to have_tag("outline/level[#{outline['levels'].count}]")
      expect(eac).not_to have_tag("outline/level[#{outline['levels'].count + 1}]")

      outline['levels'].sample['items'].each do |item|
        if item.is_a?(String)
          expect(eac).to have_tag('outline/level/item' => item)
        else
          expect(eac).to have_tag('outline/level/level/item' => item['items'][0])
        end
      end
    end
  end

  describe 'Relations' do
    before(:each) do
      as_test_user('admin') do
        @rec = create(:json_agent_person_full_subrec)

        @resource, @digital_object = [:json_resource, :json_digital_object].map do |type|
          create(type,
                 linked_agents: [{
                   'role' => ['creator', 'subject'].sample,
                   'ref' => @rec.uri
                 }])
        end

        @resource_component = create(:json_archival_object,
                                     resource: { 'ref' => @resource.uri },
                                     linked_agents: [{
                                       'role' => 'subject',
                                       'ref' => @rec.uri
                                     }])

        @digital_object_component = create(:json_digital_object_component,
                                           digital_object: { 'ref' => @digital_object.uri },
                                           linked_agents: [{
                                             'role' => 'subject',
                                             'ref' => @rec.uri
                                           }])

        @relationship = JSONModel(:agent_relationship_parentchild).new
        @relationship.relator = 'is_child_of'
        @relationship.description = 'A descriptive note.'
        @relationship.relationship_uri = 'http://example.com'
        @relationship.ref = @rec.uri

        @linked_agent = create(:json_agent_person,
                               related_agents: [@relationship.to_hash])

        @eac = get_eac(@rec)
      end
    end

    it 'maps related agents to cpfRelation' do
      uri = AppConfig[:public_proxy_url] + @linked_agent.uri
      expect(@eac).to have_tag(
        'relations/cpfRelation',
        {
          'href' => uri
        }
      )
      expect(@eac).to have_tag(
        'relations/cpfRelation/relationEntry' => @linked_agent.names[0]['primary_name']
      )
    end

    it 'maps related agents relator to cpfRelationType attribute' do
      expect(@eac).to have_tag("relations/cpfRelation[@cpfRelationType='hierarchical-parent']")
    end

    it 'maps related agents description to cpfRelation/descriptiveNote' do
      expect(@eac).to have_tag(
        'relations/cpfRelation/descriptiveNote/p' => 'A descriptive note.'
      )
    end

    it 'maps related agents relationship uri to cpfRelation arcrole attribute' do
      expect(@eac).to have_tag("relations/cpfRelation[@xlink:arcrole='http://example.com']")
    end

    it 'exports agent_resources' do
      expect(@eac)
      # resource = @rec['agent_resources'].first

      expect(@eac).to have_tag('relations/resourceRelation[@resourceRelationType]')
      expect(@eac).to have_tag('relations/resourceRelation[@xlink:arcrole]')
      expect(@eac).to have_tag('relations/resourceRelation[@xlink:role]')
      expect(@eac).to have_tag('relations/resourceRelation[@xlink:href]')
      expect(@eac).to have_tag('relations/resourceRelation[@xlink:show]')
      expect(@eac).to have_tag('relations/resourceRelation[@xlink:title]')
      expect(@eac).to have_tag('relations/resourceRelation/relationEntry')
      expect(@eac).to have_tag('relations/resourceRelation/placeEntry')
      expect(@eac).to have_tag('relations/resourceRelation/date')
    end

    it 'maps related resources and components to resourceRelation' do
      role = @resource.linked_agents[0]['role'] + 'Of'
      expect(@eac).to have_tag('relations/resourceRelation', { 'resourceRelationType' => role })
      expect(@eac).to have_tag("relations/resourceRelation[@resourceRelationType='#{role}']/relationEntry" => @resource.title)
      expect(@eac).to have_tag('relations/resourceRelation/relationEntry' => @resource_component.title)
    end

    it 'maps related digital objects and components to resourceRelation' do
      role = @digital_object.linked_agents[0]['role'] + 'Of'
      expect(@eac).to have_tag("relations/resourceRelation[@resourceRelationType='#{role}']/relationEntry" => @digital_object.title)
      expect(@eac).to have_tag('relations/resourceRelation/relationEntry' => @digital_object_component.title)
    end
  end

  describe "Metadata Rights Declaration" do
    before(:all) do
      as_test_user('admin', true) do
        @agent = create(:json_agent_person,
                        :metadata_rights_declarations => [build(:json_metadata_rights_declaration)])
        @eac = get_eac(@agent)
        raise Sequel::Rollback
      end
    end

    it 'maps metadata rights declaration to control/rightsDeclaration' do
      license_translation = I18n.t("enumerations.metadata_license.#{@agent.metadata_rights_declarations[0]['license']}")
      expect(@eac).to have_tag("control/rightsDeclaration/citation",
                               _text: license_translation,
                               href: @agent.metadata_rights_declarations[0]['file_uri'],
                               arcrole: @agent.metadata_rights_declarations[0]['xlink_arcrole_attribute'],
                               role: @agent.metadata_rights_declarations[0]['xlink_role_attribute'])
      expect(@eac).to have_tag("control/rightsDeclaration/descriptiveNote/p" => @agent.metadata_rights_declarations[0]["descriptive_note"])
      expect(@eac).to have_tag("control/rightsDeclaration/abbr" => @agent.metadata_rights_declarations[0]["license"])
    end

    it "puts abbreviation before citation before descriptivenote" do
      expect(@eac).to have_tag("xmlns:rightsDeclaration/xmlns:abbr/following-sibling::xmlns:citation")
      expect(@eac).to have_tag("xmlns:rightsDeclaration/xmlns:citation/following-sibling::xmlns:descriptiveNote")
    end
  end
end
