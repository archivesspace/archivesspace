require_relative "spec_helper.rb"
require_relative '../app/converters/lib/utils'


describe ASpaceImport::Utils do

  before(:all) do
    @dummy_class = Class.new do
      extend(ASpaceImport::Utils)
    end
  end


  describe :property_type do

    it "generates a type label for a property in a schema" do
      a = JSONModel::JSONModel(:archival_object).new
      expect(ASpaceImport::Utils.get_property_type(a.class.schema['properties']['title'])).to eq([:string, nil])
      expect(ASpaceImport::Utils.get_property_type(a.class.schema['properties']['subjects'])).to eq([:record_ref_list, 'subject'])
    end

    it "raises an exception if it can't generate a label for a schema property" do
      a = JSONModel::JSONModel(:archival_object).new
      phony_prop = a.class.schema['properties']['title'].clone
      phony_prop['type'] = 'bubble'
      expect {
        ASpaceImport::Utils.get_property_type(phony_prop)
      }.to raise_exception(ASpaceImport::Utils::ASpaceImportException)
    end

  end

  describe :normalize_boolean do

    let(:normalize) { ASpaceImport::Utils.normalize_boolean }

    it "recognizes affirmative tokens regardless of case, padding, or type" do
      ['1', 'T', 'Y', 'YES', 'TRUE', 't', 'yes', 'True', ' y ', 1, true].each do |value|
        expect(normalize.call(value)).to eq(true), "expected #{value.inspect} to normalize to true"
      end
    end

    it "recognizes negative tokens regardless of case, padding, or type" do
      ['0', 'F', 'N', 'NO', 'FALSE', 'f', 'no', 'False', ' n ', 0, false].each do |value|
        expect(normalize.call(value)).to eq(false), "expected #{value.inspect} to normalize to false"
      end
    end

    it "returns nil for blank values so the record falls back to its default" do
      [nil, "", "   "].each do |value|
        expect(normalize.call(value)).to be_nil, "expected #{value.inspect} to normalize to nil"
      end
    end

    it "raises for values it cannot interpret" do
      ["nil", "null", "NULL", "none", "empty", "NaN", "2", "yes please"].each do |value|
        expect {
          normalize.call(value)
        }.to raise_error(ASpaceImport::Utils::UnrecognizedBooleanValue),
             "expected #{value.inspect} to be rejected"
      end
    end

  end

  describe :record_uri do

    it "builds a URI from a bare numeric ID" do
      expect(ASpaceImport::Utils.record_uri(:subject, "197")).to eq("/subjects/197")
      expect(ASpaceImport::Utils.record_uri(:agent_person, " 5 ")).to eq("/agents/people/5")
    end

    it "accepts a full URI of the expected type and returns it unchanged" do
      expect(ASpaceImport::Utils.record_uri(:subject, "/subjects/197")).to eq("/subjects/197")
      expect(ASpaceImport::Utils.record_uri(:agent_family, " /agents/families/5 ")).to eq("/agents/families/5")
    end

    it "rejects a bare value that is not a positive integer" do
      ["abc", "1.5", "5a", "-1", "import_abc123"].each do |value|
        expect {
          ASpaceImport::Utils.record_uri(:subject, value)
        }.to raise_error(ASpaceImport::Utils::InvalidRecordReference) {|error|
          expect(error.reason).to eq(:invalid_id)
        }
      end
    end

    it "rejects a URI belonging to a different record type" do
      expect {
        ASpaceImport::Utils.record_uri(:subject, "/agents/people/5")
      }.to raise_error(ASpaceImport::Utils::InvalidRecordReference) {|error|
        expect(error.reason).to eq(:unrecognized_uri)
      }
    end

    it "rejects a malformed URI rather than treating it as a bare ID" do
      ["/subjects/abc", "/subjects/", "/"].each do |value|
        expect {
          ASpaceImport::Utils.record_uri(:subject, value)
        }.to raise_error(ASpaceImport::Utils::InvalidRecordReference) {|error|
          expect(error.reason).to eq(:unrecognized_uri)
        }
      end
    end

  end

  describe :update_record_references do

    it "updates the references in a json object by mapping them to the references provided in a source set" do
      a_parent = build(:json_archival_object)
      a1 = build(:json_archival_object)
      a2 = build(:json_archival_object)

      a_parent.uri = a_parent.class.uri_for(ASpaceImport::Utils.mint_id, :repo_id => 2)
      old_uri = a_parent.uri

      a1.parent = a2.parent = {"ref" => a_parent.uri}

      expect(a1.parent['ref']).to eq(a_parent.uri)
      expect(a2.parent['ref']).to eq(a_parent.uri)

      a_parent.uri = a_parent.class.uri_for(ASpaceImport::Utils.mint_id, :repo_id => 2)
      expect(a_parent.uri).not_to eq(old_uri)

      a1 = ASpaceImport::Utils.update_record_references(a1.to_hash(:raw), {old_uri => a_parent.uri})

      expect(a1['parent']['ref']).to eq(a_parent.uri)
      expect(a2['parent']['ref']).not_to eq(a_parent.uri)
    end
  end

end
