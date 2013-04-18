require_relative "spec_helper.rb"

describe ASpaceImport::Crosswalk do

  before(:all) do
    ASpaceImport::Crosswalk.init(:crosswalk => 'ead')
    @dummy_class = Class.new do
      extend(ASpaceImport::Crosswalk)
    end
    
    @vocab = build(:json_vocab)
    @vocab.uri = @vocab.class.uri_for(1, :repo_id => 2)
  end
  

  describe :property_type do

    it "generates a type label for a property in a schema" do
      a = JSONModel::JSONModel(:archival_object).new
      ASpaceImport::Crosswalk.get_property_type(a.class.schema['properties']['title']).should eq([:string, nil])
      ASpaceImport::Crosswalk.get_property_type(a.class.schema['properties']['subjects']).should eq([:record_ref_list, 'subject'])
    end
    
    it "raises an exception if it can't generate a label for a schema property" do
      a = JSONModel::JSONModel(:archival_object).new
      phony_prop = a.class.schema['properties']['title'].clone
      phony_prop['type'] = 'bubble'
      expect {
        ASpaceImport::Crosswalk.get_property_type(phony_prop)
      }.to raise_exception(ASpaceImport::Crosswalk::CrosswalkException)
    end
    
  end
  
  describe :update_record_references do
    
    it "updates the references in a json object by mapping them to the references provided in a source set" do
      a_parent = build(:json_archival_object, :level => "alpha")
      a1 = build(:json_archival_object, :level => "beta")
      a2 = build(:json_archival_object, :level => "epsilon")
      
      a_parent.uri = a_parent.class.uri_for(ASpaceImport::Crosswalk.mint_id, :repo_id => 2) 
      old_uri = a_parent.uri
      
      a1.parent = a2.parent = {"ref" => a_parent.uri}

      expect(a1.parent['ref']).to eq(a_parent.uri)
      expect(a2.parent['ref']).to eq(a_parent.uri)
      
      a_parent.uri = a_parent.class.uri_for(ASpaceImport::Crosswalk.mint_id, :repo_id => 2) 
      expect(a_parent.uri).to_not eq(old_uri)
      
      ASpaceImport::Crosswalk.update_record_references(a1, {old_uri => a_parent}) {|json| json.uri}

      expect(a1.parent['ref']).to eq(a_parent.uri)
      expect(a2.parent['ref']).to_not eq(a_parent.uri)
    end
  end
      
  
  describe :initialize_receiver do
    
    it "creates a receiver class for a JSON model property" do
      a = JSONModel::JSONModel(:archival_object).new
      xdef = {'xpath' => ["//subject"]}
      receiver_class = ASpaceImport::Crosswalk.initialize_receiver('subjects', a.class.schema['properties']['subjects'], xdef)
      receiver = receiver_class.new(a)
      receiver.to_s.should match(/^Property Receiver for archival_object#[0-9]*#subjects$/)
    end
  end
  
  describe ASpaceImport::Crosswalk::PropertyReceiver do

    it "can set a string property on a json object while applying a crosswalk procedure" do
      a = JSONModel::JSONModel(:archival_object).new
      title_part1 = generate(:alphanumstr)
      title_part2 = generate(:alphanumstr)
      full_title = "#{title_part1}#{title_part2}"
            
      xdef = {'procedure' => "|val| val << '#{title_part2}'"}
      
      receiver_class = ASpaceImport::Crosswalk.initialize_receiver('title', a.class.schema['properties']['title'], xdef)
      receiver = receiver_class.new(a)
      receiver.receive(title_part1)
      
      expect(a.title).to eq(full_title)
    end
    
    it "can set a subrecord property on a json object" do
      a = JSONModel::JSONModel(:archival_object).new
      t = build(:json_term, :vocabulary => @vocab.uri, :term_type => "cultural_context")
      s = build(:json_subject, :terms => [t], :vocabulary => @vocab.uri)
      s.uri = s.class.uri_for(ASpaceImport::Crosswalk.mint_id)
      
      xdef = {}
      
      receiver_class = ASpaceImport::Crosswalk.initialize_receiver('subjects', a.class.schema['properties']['subjects'], xdef)
      receiver = receiver_class.new(a)
      receiver.receive(s)
      
      expect(a.subjects[0]['ref']).to eq(s.uri)      
    end

  end  

end