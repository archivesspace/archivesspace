require 'spec_helper'
require 'converter_spec_helper'

require_relative '../app/converters/eac_converter'

describe 'EAC converter' do

  let(:my_converter) {
    EACConverter
  }

  let(:person_agent_1) {
    File.expand_path("../app/exporters/examples/eac/feynman-richard-phillips-1918-1988-cr.xml",
                     File.dirname(__FILE__))
  }

  let(:person_agent_2) {
    File.expand_path("../app/exporters/examples/eac/MMeT-C_2012_RCR00751.xml",
                     File.dirname(__FILE__))
  }

  let(:person_agent_3) {
    File.expand_path("../app/exporters/examples/eac/xmleac.xml",
                     File.dirname(__FILE__))
  }

  let(:corp_agent_1) {
    File.expand_path("../app/exporters/examples/eac/SIA_NMAH_EACAmericanHistory.xml",
                     File.dirname(__FILE__))
  }

  let(:corp_agent_2) {
    File.expand_path("../app/exporters/examples/eac/SIA_NMAH_EACAmericanHistory_modified.xml",
                     File.dirname(__FILE__))
  }

  let(:family_agent_1) {
    File.expand_path("../app/exporters/examples/eac/US-CtY-BR_2012_Boswell.xml",
                     File.dirname(__FILE__))
  }

  let(:family_agent_2) {
    File.expand_path("../app/exporters/examples/eac/US-CtY-BR_2012_Boswell_modified.xml",
                     File.dirname(__FILE__))
  }


  describe "people agents" do
    it "imports primary_name" do
      record = convert(person_agent_1).select {|r| r['jsonmodel_type'] == "agent_person"}.first

      expect(record).not_to be_nil
      expect(record['names'][0]['primary_name']).to eq("Feynman, Richard Phillips, 1918-1988.")
    end

    it "imports bioghist notes" do
      record = convert(person_agent_2).select {|r| r['jsonmodel_type'] == "agent_person"}.first
      note = record["notes"].first["subnotes"].first


      expect(record).not_to be_nil
      expect(note).not_to be_nil

      expect(note["content"]).to match(/Richard H. Lufkin was a shoe machine engineer/)
    end

    it "imports general context notes" do
      record = convert(person_agent_3).select {|r| r['jsonmodel_type'] == "agent_person"}.first

      note = record["notes"][1]["subnotes"].first

      expect(record).not_to be_nil
      expect(note).not_to be_nil

      expect(note["content"]).to match(/one/)
      expect(note["content"]).to match(/two/)
      expect(note["content"]).to match(/three/)
    end

    it "imports recordId as primary agent_record_identifier" do
      record = convert(person_agent_2).select {|r| r['jsonmodel_type'] == "agent_person"}.first

      ari = record["agent_record_identifiers"].first


      expect(ari).not_to be_nil

      expect(ari["record_identifier"]).to eq("RCR00751")
      expect(ari["primary_identifier"]).to eq(true)
    end

    it "imports otherRecordId as not primary agent_record_identifier" do
      record = convert(person_agent_3).select {|r| r['jsonmodel_type'] == "agent_person"}.first

      ars = record["agent_record_identifiers"]

      expect(ars.length).to eq(8)
      expect(ars[1]["record_identifier"]).to eq("11850391X")
      expect(ars[1]["primary_identifier"]).to eq(false)
      expect(ars[1]["identifier_type"]).to eq("PPN")

      expect(ars[2]["record_identifier"]).to eq("http://kalliope-verbund.info/gnd/11850391X")
      expect(ars[2]["primary_identifier"]).to eq(false)
      expect(ars[2]["identifier_type"]).to eq("uriKPE")
    end

    it "imports agent_record_control tags" do
      record = convert(person_agent_3).select {|r| r['jsonmodel_type'] == "agent_person"}.first

      arc = record["agent_record_controls"].first

      expect(arc["maintenance_status"]).to eq("new")
      expect(arc["agency_name"]).to eq("Deutsche Nationalbibliothek")
      expect(arc["maintenance_agency"]).to eq("DE-101")
      expect(arc["maintenance_agency_note"]).to eq("Agency Note")
      expect(arc["publication_status"]).to eq("approved")
      expect(arc["language"]).to eq("ger")
      expect(arc["script"]).to eq("Latn")
      expect(arc["language_note"]).to eq("Language Note")
    end

    it "imports agent_conventions_declaration tags" do
      record = convert(person_agent_3).select {|r| r['jsonmodel_type'] == "agent_person"}.first

      acd = record["agent_conventions_declarations"].first

      expect(acd["name_rule"]).to eq("rda")
      expect(acd["citation"]).to eq("The Citation")
      expect(acd["file_uri"]).to eq("http://www.google.com")
      expect(acd["file_version_xlink_actuate_attribute"]).to eq("onRequest")
      expect(acd["file_version_xlink_show_attribute"]).to eq("new")
      expect(acd["xlink_title_attribute"]).to eq("xlink title")
      expect(acd["xlink_role_attribute"]).to eq("xlink role")
      expect(acd["xlink_arcrole_attribute"]).to eq("xlink arcrole")
      expect(acd["descriptive_note"]).to eq("Convention Note")
      expect(acd["last_verified_date"]).to eq("2000-07-01")
    end

    it "imports agent_maintenance_history tags" do
      record = convert(person_agent_3, true).select {|r| r['jsonmodel_type'] == "agent_person"}.first

      mh = record["agent_maintenance_histories"].first

      expect(record["agent_maintenance_histories"].length).to eq(2)

      expect(mh["maintenance_event_type"]).to eq("created")
      expect(mh["maintenance_agent_type"]).to eq("human")
      expect(mh["agent"]).to eq("W4")
      expect(mh["event_date"]).to eq("1988-07-01")
      expect(mh["descriptive_note"]).to eq("Event note 1")
    end

    it "does not import agent_maintenance_history tags if option is not set" do
      record = convert(person_agent_3, false).select {|r| r['jsonmodel_type'] == "agent_person"}.first

      expect(record["agent_maintenance_histories"].length).to eq(0)
    end

    it "imports agent_source tags" do
      record = convert(person_agent_3).select {|r| r['jsonmodel_type'] == "agent_person"}.first

      s = record["agent_sources"].first

      expect(s["source_entry"]).to eq("Pressearchiv des Herder-Instituts Marburg")
      expect(s["file_uri"]).to eq("http://www.googlew.com")
      expect(s["file_version_xlink_actuate_attribute"]).to eq("onRequest")
      expect(s["file_version_xlink_show_attribute"]).to eq("new")
      expect(s["xlink_title_attribute"]).to eq("xlink title")
      expect(s["xlink_role_attribute"]).to eq("xlink role")
      expect(s["xlink_arcrole_attribute"]).to eq("xlink arcrole")
      expect(s["descriptive_note"]).to eq("Source Note")
      expect(s["last_verified_date"]).to eq("2001-07-01")
    end

    it "imports agent_identifier tags" do
      record = convert(person_agent_3).select {|r| r['jsonmodel_type'] == "agent_person"}.first

      id = record["agent_identifiers"].first

      expect(id["entity_identifier"]).to eq("auto gen number")
      expect(id["identifier_type"]).to eq("PPX")
    end

    it "imports part with no attrs as primary_name" do
      record = convert(person_agent_3).select {|r| r['jsonmodel_type'] == "agent_person"}.first

      expect(record).not_to be_nil
      expect(record['names'][1]['primary_name']).to eq("short")
    end

    it "imports other parts of name" do
      record = convert(person_agent_3).select {|r| r['jsonmodel_type'] == "agent_person"}.first

      expect(record['names'][0]['title']).to eq("Dr.")
      expect(record['names'][0]['prefix']).to eq("Mrs.")
      expect(record['names'][0]['primary_name']).to eq("Arendt")
      expect(record['names'][0]['rest_of_name']).to eq("Hannah")
      expect(record['names'][0]['suffix']).to eq("IV")
      expect(record['names'][0]['number']).to eq("4")
      expect(record['names'][0]['fuller_form']).to eq("Fuller Form")
      expect(record['names'][0]['dates']).to eq("1906-1975")
      expect(record['names'][0]['qualifier']).to eq("qualifier")
      expect(record['names'][0]['language']).to eq("eng")
      expect(record['names'][0]['script']).to eq("Latn")
      expect(record['names'][0]['transliteration']).to eq("int_std")
    end

    it "imports parallel names" do
      record = convert(person_agent_3).select {|r| r['jsonmodel_type'] == "agent_person"}.first

      expect(record["names"].count).to eq(4)
      expect(record["names"][3]["parallel_names"].count).to eq(24)

      expect(record["names"][3]["parallel_names"].first["primary_name"]).to match(/Johanna/)
      expect(record["names"][3]["parallel_names"].last["primary_name"]).to match(/阿伦特/)
    end

    it "imports name use dates" do
      record = convert(person_agent_3).select {|r| r['jsonmodel_type'] == "agent_person"}.first

      expect(record['names'][0]['use_dates'].length).to eq(2)
      expect(record['names'][1]['use_dates'].length).to eq(1)

      expect(record["names"][0]["use_dates"][0]["date_label"]).to eq("usage")
      expect(record["names"][0]["use_dates"][0]["structured_date_single"]["date_expression"]).to match(/1802 December 27/)
      expect(record["names"][0]["use_dates"][1]["date_label"]).to eq("usage")
      expect(record["names"][0]["use_dates"][1]["structured_date_range"]["begin_date_expression"]).to match(/1745 November 12/)

      expect(record["names"][1]["use_dates"][0]["date_label"]).to eq("usage")
      expect(record["names"][1]["use_dates"][0]["structured_date_range"]["begin_date_expression"]).to match(/1746 November 12/)

    end

    it "imports alternative names" do
      record = convert(person_agent_3).select {|r| r['jsonmodel_type'] == "agent_person"}.first

      expect(record).not_to be_nil
      expect(record['names'][1]['authorized']).to eq(false)
      expect(record['names'][1]['source']).to eq("VIAF")
    end

    it "imports dates of existence" do
      record = convert(person_agent_3).select {|r| r['jsonmodel_type'] == "agent_person"}.first

      expect(record).not_to be_nil
      expect(record['dates_of_existence'].length).to eq(2)

      expect(record['dates_of_existence'][0]['structured_date_single']["date_expression"]).to match(/1802 December 27/)
      expect(record['dates_of_existence'][0]['date_label']).to eq("existence")
      expect(record['dates_of_existence'][1]['structured_date_range']["begin_date_expression"]).to match(/1742 November 12/)
      expect(record['dates_of_existence'][1]['date_label']).to eq("existence")
    end

    it "imports places as subjects" do
      full_record = convert(person_agent_3)

      agent_record = full_record.select {|r| r['jsonmodel_type'] == "agent_person"}.first
      subject_records = full_record.select {|r| r['jsonmodel_type'] == "subject"}
      geo_subjects = subject_records.select {|r| r['terms'].first['term_type'] == "geographic"}

      expect(geo_subjects.length).to eq(3)
      expect(geo_subjects.first["authority_id"]).to eq("GND")

      expect(agent_record["agent_places"].length).to eq(3)
      expect(agent_record["agent_places"][0]["subjects"][0]["ref"]).to eq(geo_subjects[2]["uri"])

      expect(agent_record["agent_places"][0]["dates"][0]["date_label"]).to eq("DE-588-4099668-2")
      expect(agent_record["agent_places"][0]["dates"][0]["structured_date_single"]["date_expression"]).to match(/1802 December 27/)
      expect(agent_record["agent_places"][0]["notes"][0]["content"]).to match(/text note/)

      expect(agent_record["agent_places"][1]["dates"][0]["date_label"]).to eq("DE-588-4031541-1")
      expect(agent_record["agent_places"][1]["dates"][0]["structured_date_range"]["begin_date_expression"]).to match(/1743 November 12/)
      expect(agent_record["agent_places"][1]["notes"][0]["content"].first).to match(/citation/)

    end

    it "imports occupations as subjects" do
      full_record = convert(person_agent_3)

      agent_record = full_record.select {|r| r['jsonmodel_type'] == "agent_person"}.first
      subject_records = full_record.select {|r| r['jsonmodel_type'] == "subject"}
      occupation_subjects = subject_records.select {|r| r['terms'].first['term_type'] == "occupation"}

      expect(occupation_subjects.length).to eq(6)
      expect(agent_record["agent_occupations"].length).to eq(6)
    end

    it "imports functions as subjects" do
      full_record = convert(person_agent_3)

      agent_record = full_record.select {|r| r['jsonmodel_type'] == "agent_person"}.first
      subject_records = full_record.select {|r| r['jsonmodel_type'] == "subject"}
      function_subjects = subject_records.select {|r| r['terms'].first['term_type'] == "function"}

      expect(function_subjects.length).to eq(3)
      expect(agent_record["agent_functions"].length).to eq(3)
    end

    it "imports topics as subjects" do
      full_record = convert(person_agent_3)

      agent_record = full_record.select {|r| r['jsonmodel_type'] == "agent_person"}.first
      subject_records = full_record.select {|r| r['jsonmodel_type'] == "subject"}
      topic_subjects = subject_records.select {|r| r['terms'].first['term_type'] == "topical"}

      expect(topic_subjects.length).to eq(1)
      expect(agent_record["agent_topics"].length).to eq(1)
    end

    it "imports gender" do
      full_record = convert(person_agent_3)

      agent_record = full_record.select {|r| r['jsonmodel_type'] == "agent_person"}.first

      expect(agent_record["agent_genders"].length).to eq(1)
      expect(agent_record["agent_genders"][0]["gender"]).to eq("Woman")

      expect(agent_record["agent_genders"][0]["notes"][0]["content"]).to match(/d-note/)

      expect(agent_record["agent_genders"][0]["dates"][0]["date_label"]).to eq("DE-588-4099668-2")
      expect(agent_record["agent_genders"][0]["dates"][0]["structured_date_single"]["date_expression"]).to match(/1802 December 27/)

      # date inside <dateSet>
      expect(agent_record["agent_genders"][0]["dates"][1]["structured_date_range"]["begin_date_expression"]).to match(/1742 November 12/)
    end

    it "imports alternate sets" do
      full_record = convert(person_agent_3)

      agent_record = full_record.select {|r| r['jsonmodel_type'] == "agent_person"}.first

      expect(agent_record["agent_alternate_sets"].length).to eq(1)
      expect(agent_record["agent_alternate_sets"][0]["set_component"]).to match(/set component/)
      expect(agent_record["agent_alternate_sets"][0]["descriptive_note"]).to match(/Note of description/)
      expect(agent_record["agent_alternate_sets"][0]["file_uri"]).to eq("href")
      expect(agent_record["agent_alternate_sets"][0]["xlink_title_attribute"]).to eq("title")
      expect(agent_record["agent_alternate_sets"][0]["xlink_role_attribute"]).to eq("role")
      expect(agent_record["agent_alternate_sets"][0]["xlink_arcrole_attribute"]).to eq("arcrole")
      expect(agent_record["agent_alternate_sets"][0]["file_version_xlink_show_attribute"]).to eq("new")

      expect(agent_record["agent_alternate_sets"][0]["file_version_xlink_actuate_attribute"]).to eq("none")
    end

    it "imports languages used" do
      full_record = convert(person_agent_3)

      agent_record = full_record.select {|r| r['jsonmodel_type'] == "agent_person"}.first

      expect(agent_record["used_languages"].length).to eq(2)
      expect(agent_record["used_languages"][0]["language"]).to eq("eng")
      expect(agent_record["used_languages"][0]["script"]).to eq("Latn")

      expect(agent_record["used_languages"][0]["notes"][0]["content"]).to match(/Published works in English and Spanish/)
    end

    xit "imports related agents" do
      full_record = convert(person_agent_3)

      puts full_record.inspect
    end

    it "imports related external resources" do
      full_record = convert(person_agent_3)

      agent_record = full_record.select {|r| r['jsonmodel_type'] == "agent_person"}.first

      expect(agent_record["agent_resources"].length).to eq(1)

      ar = agent_record['agent_resources'].first
      expect(ar["file_uri"]).to eq("http://www.google.com")
      expect(ar["file_version_xlink_actuate_attribute"]).to eq("onRequest")
      expect(ar["file_version_xlink_show_attribute"]).to eq("new")
      expect(ar["xlink_title_attribute"]).to eq("xlink title")
      expect(ar["xlink_role_attribute"]).to eq("xlink role")
      expect(ar["xlink_arcrole_attribute"]).to eq("xlink arcrole")
      expect(ar["last_verified_date"]).to eq("2000-07-01")

      expect(ar["linked_resource"]).to eq("Department of Romance Languages records")
      expect(ar["linked_resource_description"]).to eq("note!")

      expect(ar["dates"][0]["structured_date_range"]["begin_date_expression"]).to match(/1744 November 12/)
    end

  end

  describe "corporate agents" do
    it "imports part with no attrs as primary_name" do
      record = convert(corp_agent_1).select {|r| r['jsonmodel_type'] == "agent_corporate_entity"}.first

      expect(record).not_to be_nil
      expect(record['names'][0]['primary_name']).to eq("National Museum of American History (U.S.)")
    end

    it "imports other parts of name" do
      record = convert(corp_agent_2).select {|r| r['jsonmodel_type'] == "agent_corporate_entity"}.first

      expect(record).not_to be_nil

      expect(record['names'][0]['primary_name']).to eq("National Museum of American History (U.S.)")
      expect(record['names'][0]['subordinate_name_1']).to eq("sub1")
      expect(record['names'][0]['subordinate_name_2']).to eq("sub2")
      expect(record['names'][0]['number']).to eq("number")
      expect(record['names'][0]['location']).to eq("location")
      expect(record['names'][0]['dates']).to eq("1906-1975")
      expect(record['names'][0]['qualifier']).to eq("qualifier")
      expect(record['names'][0]['source']).to eq("unknown")
      expect(record['names'][0]['authorized']).to eq(true)
      expect(record['names'][0]['language']).to eq("eng")
      expect(record['names'][0]['script']).to eq("Latn")
    end

    it "imports alternative names" do
      record = convert(corp_agent_2).select {|r| r['jsonmodel_type'] == "agent_corporate_entity"}.first

      expect(record).not_to be_nil
      expect(record['names'][1]['authorized']).to eq(false)
      expect(record['names'][1]['source']).to eq("local")
    end

    it "imports legal status notes" do
      record = convert(corp_agent_1).select {|r| r['jsonmodel_type'] == "agent_corporate_entity"}.first

      legal_notes = record["notes"].select{|n| n['jsonmodel_type'] == "note_legal_status"}

      expect(legal_notes.length).to eq(1)
      expect(legal_notes.first["subnotes"][0]['content'].first).to eq("citation")
      expect(legal_notes.first["subnotes"][1]['content']).to eq("dnote")
    end

    it "imports mandate notes" do
      record = convert(corp_agent_1).select {|r| r['jsonmodel_type'] == "agent_corporate_entity"}.first

      mandate_notes = record["notes"].select{|n| n['jsonmodel_type'] == "note_mandate"}

      expect(mandate_notes.length).to eq(1)
      expect(mandate_notes.first["subnotes"][0]['content'].first).to eq("citation")
      expect(mandate_notes.first["subnotes"][1]['content']).to eq("dnote")
    end

    it "imports structure notes" do
      record = convert(corp_agent_1).select {|r| r['jsonmodel_type'] == "agent_corporate_entity"}.first

      sog_notes = record["notes"].select{|n| n['jsonmodel_type'] == "note_structure_or_genealogy"}

      expect(sog_notes.length).to eq(1)
      expect(sog_notes.first["subnotes"][0]['content']).to match(/citation/)
      expect(sog_notes.first["subnotes"][0]['content']).to match(/one/)
      expect(sog_notes.first["subnotes"][0]['content']).to match(/two/)
      expect(sog_notes.first["subnotes"][0]['content']).to match(/three/)
    end
  end

  describe "family agents" do
    it "imports part with no attrs as primary_name" do
      record = convert(family_agent_1).select {|r| r['jsonmodel_type'] == "agent_family"}.first

      expect(record).not_to be_nil
      expect(record['names'][0]['family_name']).to eq("Boswell family")
    end

    it "imports other parts of name" do
      record = convert(family_agent_2).select {|r| r['jsonmodel_type'] == "agent_family"}.first

      expect(record).not_to be_nil

      expect(record['names'][0]['family_name']).to eq("Boswell family")
      expect(record['names'][0]['location']).to eq("location")
      expect(record['names'][0]['family_type']).to eq("family_type")
      expect(record['names'][0]['dates']).to eq("1906-1975")
      expect(record['names'][0]['qualifier']).to eq("qualifier")
      expect(record['names'][0]['source']).to eq("lcnaf")
      expect(record['names'][0]['authorized']).to eq(true)
      expect(record['names'][0]['language']).to eq("eng")
      expect(record['names'][0]['script']).to eq("Latn")
    end

    it "imports alternative names" do
      record = convert(family_agent_2).select {|r| r['jsonmodel_type'] == "agent_family"}.first

      expect(record).not_to be_nil
      expect(record['names'][1]['authorized']).to eq(false)
      expect(record['names'][1]['source']).to eq("lcnaf")
    end

    it "imports structure notes" do
      record = convert(family_agent_2).select {|r| r['jsonmodel_type'] == "agent_family"}.first

      sog_notes = record["notes"].select{|n| n['jsonmodel_type'] == "note_structure_or_genealogy"}

      expect(sog_notes.length).to eq(2)
      expect(sog_notes.first["subnotes"][0]['content']).to match(/citation/)
      expect(sog_notes.first["subnotes"][0]['content']).to match(/one/)
      expect(sog_notes.first["subnotes"][0]['content']).to match(/two/)
      expect(sog_notes.first["subnotes"][0]['content']).to match(/three/)
    end
  end
end
