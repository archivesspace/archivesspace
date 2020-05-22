require 'spec_helper'
require_relative '../app/lib/indexer_common'

describe "indexer common" do
  before(:all) do
    @@record_types = IndexerCommonConfig.record_types
    @@global_types = IndexerCommonConfig.global_types
    @@resolved_attributes = IndexerCommonConfig.resolved_attributes
    @backend_url = "#{AppConfig[:backend_url]}"
  end
  before(:each) do
    @ic = IndexerCommon.new(@backend_url)
  end
  describe "initialize" do
    it "initializes with the backend url" do
      expect(@ic.instance_variable_get(:@backend_url)).to eq("#{AppConfig[:backend_url]}")
    end
    it "initializes @delete_hooks to an empty array" do
      expect(@ic.instance_variable_get(:@delete_hooks)).to eq([])
    end
    it "initializes @batch_hooks to an empty array" do
      expect(@ic.instance_variable_get(:@batch_hooks)).to eq([])
    end
    it "initializes @current_session to nil" do
      expect(@ic.instance_variable_get(:@current_session)).to be_nil
    end
    it "initializes @extra_documents_hooks to nil" do
      expect(@ic.instance_variable_get(:@extra_documents_hooks)).not_to be_nil
    end
    it "initializes @document_prepare_hooks to nil" do
      expect(@ic.instance_variable_get(:@document_prepare_hooks)).not_to be_nil
    end
    it "initializes @@records_with_children to an empty array" do
      expect(IndexerCommon.class_variable_get(:@@records_with_children)).to include("collection_management")
    end
    it "initializes @@init_hooks to an empty array" do
      expect(IndexerCommon.class_variable_get(:@@init_hooks)).to eq([])
    end
    it "initializes @@paused_until to Time.now" do
      pu = IndexerCommon.class_variable_get(:@@paused_until)
      expect(pu.to_i).to be_within(50).of(Time.now.to_i)
    end
    it "rescues when unable to connect to the backend_url" do
      ic = IndexerCommon.new("fake_url")
      expect($stderr).to respond_to(:puts).with(1).argument
    end
    it "calls configure_doc_rules" do
      expect(@ic).to respond_to(:configure_doc_rules)
    end
  end
  describe "add_indexer_initialize_hook" do
    it "adds indexer initialize hook" do
      IndexerCommon.add_indexer_initialize_hook do | i |
        # puts i.inspect
      end
      # def self.add_indexer_initialize_hook(&block)
    end
  end
  describe "add_attribute_to_resolve" do
    describe "additional attribute not already on resolved_attributes list" do
      it "adds additional attribute to resolve list" do
        expect(IndexerCommon.class_variable_get(:@@resolved_attributes)).not_to include('test_attr')
        res_att_count = IndexerCommon.class_variable_get(:@@resolved_attributes).length
        IndexerCommon.add_attribute_to_resolve('test_attr')
        expect(IndexerCommon.class_variable_get(:@@resolved_attributes)).to include('test_attr')
        expect(IndexerCommon.class_variable_get(:@@resolved_attributes).length).to eq(res_att_count+1)
      end
    end
    describe "additional attribute already on resolved_attributes list" do
      it "does not add additional attribute to resolve list" do
        expect(IndexerCommon.class_variable_get(:@@resolved_attributes)).to include('repository')
        res_att_count = IndexerCommon.class_variable_get(:@@resolved_attributes).length
        IndexerCommon.add_attribute_to_resolve('repository')
        expect(IndexerCommon.class_variable_get(:@@resolved_attributes).length).to eq(res_att_count)
      end
    end
  end
  describe "resolved_attributes" do
    it "returns resolved attributes class variable" do
      expect(@ic.resolved_attributes).to eq(IndexerCommonConfig.resolved_attributes)
    end
  end
  describe "record_types" do
    it "returns record types class variable" do
      expect(@ic.record_types).to eq(IndexerCommonConfig.record_types)
    end
  end
  describe "pause" do
    describe "called without input param" do
      it "sets @@paused_until class variable to Time.now + 900 seconds" do
        IndexerCommon.pause
        expect(IndexerCommon.class_variable_get(:@@paused_until).to_i).to be_within(1000).of(Time.now.to_i)
        IndexerCommon.class_variable_set(:@@paused_until, Time.now)
      end
    end
    describe "called with input param" do
      it "sets @@paused_until class variable to Time.now + duration seconds" do
        IndexerCommon.pause(100)
        expect(IndexerCommon.class_variable_get(:@@paused_until).to_i).to be_within(125).of(Time.now.to_i)
        IndexerCommon.class_variable_set(:@@paused_until, Time.now)
      end
    end
  end
  describe "paused?" do
    it "returns true if paused" do
      IndexerCommon.pause(100)
      expect(IndexerCommon.paused?).to be true
      IndexerCommon.class_variable_set(:@@paused_until, Time.now)
    end
    it "returns false if not paused" do
      expect(IndexerCommon.paused?).to be false
    end
  end
  describe "generate_years_for_date_range" do
    describe "called with begin_date input param" do
      describe "called with end_date input param" do
        it "returns array of years for given date range" do
          bd = "2000/01/01"
          ed = "2005/02/01"
          expect(IndexerCommon.generate_years_for_date_range(bd, ed)).to eq(['2000', '2001', '2002', '2003', '2004', '2005'])
        end
      end
      describe "called without end_date input param" do
        it "returns empty array" do
          bd = "2000/01/01"
          expect(IndexerCommon.generate_years_for_date_range(bd, '')).to be_empty
        end
      end
    end
    describe "called without input params" do
      it "returns empty array" do
        expect(IndexerCommon.generate_years_for_date_range('', '')).to be_empty
      end
    end
  end
  describe "generate_permutations_for_identifier" do
    it "returns empty array if identifier is nil" do
      expect(IndexerCommon.generate_permutations_for_identifier(nil)).to be_empty
    end
    it "generates permutations for identifier" do
      expect(IndexerCommon.generate_permutations_for_identifier('2000.abc.george')).to eq(["2000.abc.george", "2000 abc george", "2000abcgeorge", "2000 .abc.george"])
    end
  end
  describe "generate_sort_string_for_identifier" do
    describe "called without size input param" do
      it "generates sort string for identifier with default size input of 255" do
        expect(IndexerCommon.generate_sort_string_for_identifier('abc.2000.george').length).to eq(255 * 3)
        expect(IndexerCommon.generate_sort_string_for_identifier('abc.2000.george')).to eq('abc.###########################################################################################################################################################################################################################################################000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000.george                                                                                                                                                                                                                                                        ')
      end
    end
    describe "called with size input param" do
      it "generates sort string for identifier" do
        size = 15
        expect(IndexerCommon.generate_sort_string_for_identifier('2000.abc.george', size).length).to eq(3 * size)
        expect(IndexerCommon.generate_sort_string_for_identifier('2000.abc.george', 15)).to eq('###############000000000002000.abc.george    ')
      end
    end
  end
  describe "extract_string_values" do
    it "extracts string values from arrays" do
      doc = {}
      doc['id'] = "ID"
      doc['uri'] = "URI"
      doc['title'] =  "Test record 1"
      doc['arr'] = ['type 1', 'type 2']
      expect(IndexerCommon.extract_string_values(doc)).to eq('ID URI Test record 1 type 1 type 2 ')
    end
    it "extracts string values from hashes" do
      doc = {}
      doc['id'] = "ID2"
      doc['uri'] = "URI2"
      doc['title'] =  "Test record 2"
      doc['hsh'] = {'type1': '1', 'type2': '2'}
      expect(IndexerCommon.extract_string_values(doc)).to eq('ID2 URI2 Test record 2 1 2 ')
    end
    it "extracts string values from strings" do
      doc = {}
      doc['id'] = "ID3"
      doc['uri'] = "URI3"
      doc['title'] =  "Test record 3"
      expect(IndexerCommon.extract_string_values(doc)).to eq('ID3 URI3 Test record 3 ')
    end
  end
  describe "build_fullrecord" do
    describe "record does not have finding_aid_subtitle, finding_aid_author, or names" do
      it "builds full record" do
        rec = {}
        rec['record'] = {}
        rec['record']['id'] = "ID1"
        rec['record']['uri'] = "URI1"
        rec['record']['title'] =  "Test record 1"
        expect(IndexerCommon.build_fullrecord(rec)).to eq('ID1 URI1 Test record 1 ')
      end
    end
    describe "record has finding_aid_subtitle" do
      it "builds full record" do
        rec = {}
        rec['record'] = {}
        rec['record']['id'] = "ID3"
        rec['record']['uri'] = "URI3"
        rec['record']['title'] =  "Test record 3"
        rec['record']['finding_aid_subtitle'] = 'Finding Aid Subtitle 3'
        expect(IndexerCommon.build_fullrecord(rec)).to eq('ID3 URI3 Test record 3 Finding Aid Subtitle 3 Finding Aid Subtitle 3 ')
      end
    end
    describe "record has finding_aid_author" do
      it "builds full record" do
        rec = {}
        rec['record'] = {}
        rec['record']['id'] = "ID2"
        rec['record']['uri'] = "URI2"
        rec['record']['title'] =  "Test record 2"
        rec['record']['finding_aid_author'] = 'Finding Aid Author 2'
        expect(IndexerCommon.build_fullrecord(rec)).to eq('ID2 URI2 Test record 2 Finding Aid Author 2 Finding Aid Author 2 ')
      end
    end
    describe "record has names" do
      it "builds full record" do
        rec = {}
        rec['record'] = {}
        rec['record']['id'] = "ID2"
        rec['record']['uri'] = "URI2"
        rec['record']['title'] =  "Test record 2"
        rec['record']['names'] = {'name1': 'NAME1', 'name2': 'NAME2', 'name3': 'NAME3'}
        expect(IndexerCommon.build_fullrecord(rec)).to eq('ID2 URI2 Test record 2 NAME1 NAME2 NAME3   ')
      end
    end
    describe "record has finding_aid_subtitle, finding_aid_author, and names" do
      it "builds full record" do
        rec = {}
        rec['record'] = {}
        rec['record']['id'] = "ID1"
        rec['record']['uri'] = "URI1"
        rec['record']['title'] =  "Test record 1"
        rec['record']['finding_aid_subtitle'] = 'Finding Aid Subtitle 1'
        rec['record']['finding_aid_author'] = 'Finding Aid Author 1'
        rec['record']['names'] = {'name1': 'NAME1', 'name2': 'NAME2', 'name3': 'NAME3'}
        expect(IndexerCommon.build_fullrecord(rec)).to eq('ID1 URI1 Test record 1 Finding Aid Subtitle 1 Finding Aid Author 1 NAME1 NAME2 NAME3 Finding Aid Subtitle 1 Finding Aid Author 1   ')
      end
    end
  end
  describe "add_agents" do
    describe "record has no linked agents" do
      it "does not modify doc" do
        doc = {}
        doc['id'] = "ID1"
        doc['uri'] = "URI1"
        doc['title'] =  "Test record 1"
        rec = {}
        rec['record'] = {}
        rec['record']['junk'] = "Junk"
        doc2 = doc
        @ic.add_agents(doc, rec)
        expect(doc).to eq(doc2)
      end
    end
    describe "record has linked agents" do
      xit "adds agents to doc" do
        doc = {}
        doc['id'] = "ID1"
        doc['uri'] = "URI1"
        doc['title'] =  "Test record 1"
        rec = {}
        rec['record'] = {}
        rec['record']['junk'] = "Junk"
        rec['record']['linked_agents'] = [{'ref'=>'example.com','_resolved'=>{'display_name'=>{'sort_name'=>'abc'}}}, {'ref'=>'example2.com','_resolved'=>{'display_name'=>{'sort_name'=>'xyz'}}}]
        doc2 = doc
        @ic.add_agents(doc, rec)
        expect(doc['agents']).to eq(['abc','xyz'])
      end
    end
  end
  describe "add_subjects" do
    it "adds subjects" do
      # def add_subjects(doc, record)
    end
  end
  describe "add_audit_info" do
    it "adds audit information" do
      # def add_audit_info(doc, record)
    end
  end
  describe "add_notes" do
    it "adds notes" do
      # def add_notes(doc, record)
    end
  end
  describe "add_years" do
    it "adds years" do
      # def add_years(doc, record)
    end
  end
  describe "add_level" do
    it "adds level" do
      # def add_level(doc, record)
    end
  end
  describe "add_summary" do
    it "adds summary" do
      # def add_summary(doc, record)
    end
  end
  describe "configure_doc_rules" do
    it "configures doc rules" do
      # def configure_doc_rules
    end
  end
  describe "add_document_prepare_hook" do
    it "adds document prepare hook" do
      # def add_document_prepare_hook(&block)
    end
  end
  describe "record_has_children" do
    it "determines record has children" do
      # def record_has_children(record_type)
    end
  end
  describe "records_with_children" do
    it "determines records with children" do
      # def records_with_children
    end
  end
  describe "add_extra_documents_hook" do
    it "adds extra documents" do
      # def add_extra_documents_hook(&block)
    end
  end
  describe "add_batch_hook" do
    it "adds batch hooks" do
      # def add_batch_hook(&block)
    end
  end
  describe "add_delete_hook" do
    it "adds delete hooks" do
      # def add_delete_hook(&block)
    end
  end
  describe "solr_url" do
     it "returns solr url" do
      # def solr_url
    end
  end
  describe "do_http_request" do
    it "should report if there's a timeout but not fail" do
      solr_url = @ic.solr_url
      req = Net::HTTP::Post.new("#{solr_url.path}/update")
      expect(ASHTTP).to receive(:start_uri).and_raise(Timeout::Error)
      @ic.do_http_request(solr_url, req)
    end
  end

  describe "reset_session" do
    it "resets the session" do
      # def reset_session
    end
  end
  describe "login" do
    it "does the login" do
      # def login
    end
  end
  describe "get_record_scope" do
    it "gets record scope" do
      # def get_record_scope(uri)
    end
  end
  describe "is_repository_unpublished?" do
    it "determines if the repository is unpublished" do
      # def is_repository_unpublished?(uri, values)
    end
  end
  describe "delete_records" do
    it "deletes records" do
      # def delete_records(records, opts = {})
    end
  end
  describe "dedupe_by_uri" do
    it "dedupes by uri" do
      # def dedupe_by_uri(records)
    end
  end
  describe "clean_whitespace" do
    it "cleans whitespace" do
      # def clean_whitespace(doc)
    end
  end
  describe "clean_for_sort" do
    it "cleans for sort" do
      # def clean_for_sort(value)
    end
  end
  describe "index_records" do
    it "indexes record" do
      # def index_records(records, timing = IndexerTiming.new)
    end
  end
  describe "index_batch" do
    it "indexes batch" do
      # def index_batch(batch, timing = IndexerTiming.new, opts = {})
    end
  end
  describe "send_commit" do
    it "report if there's a timeout but not fail" do
      expect(ASHTTP).to receive(:start_uri).and_raise(Timeout::Error)
      @ic.send_commit
    end
  end
  describe "paused?" do
    it "determines if it is paused" do
      # def paused?
    end
  end
  describe "skip_index_record?" do
    it "determines if it should skip index record" do
      # def skip_index_record?(record)
    end
  end
  describe "skip_index_doc?" do
    it "determines if it should skip index doc" do
      # def skip_index_doc?(doc)
    end
  end
  describe "apply_pui_fields" do
    it "applies PUI fields" do
      # def apply_pui_fields(doc, record)
    end
  end
  describe "sanitize_json method" do
    it "removes agent_contact data when indexing agent_person" do
      agent = build(:json_agent_person)

      expect(agent["agent_contacts"].length).to_not eq(0)
      sanitized_agent = @ic.sanitize_json(agent)

      expect(agent["agent_contacts"].empty?).to be_truthy
    end

    it "removes agent_contact data when indexing agent_family" do
      agent = build(:json_agent_family)

      expect(agent["agent_contacts"].length).to_not eq(0)
      sanitized_agent = @ic.sanitize_json(agent)

      expect(agent["agent_contacts"].empty?).to be_truthy
    end

    it "removes agent_contact data when indexing agent_corporate_entity" do
      agent = build(:json_agent_corporate_entity)

      expect(agent["agent_contacts"].length).to_not eq(0)
      sanitized_agent = @ic.sanitize_json(agent)

      expect(agent["agent_contacts"].empty?).to be_truthy
    end

    it "removes agent_contact data when indexing agent_software" do
      agent = build(:json_agent_software)

      expect(agent["agent_contacts"].length).to_not eq(0)
      sanitized_agent = @ic.sanitize_json(agent)

      expect(agent["agent_contacts"].empty?).to be_truthy
    end
  end

end
