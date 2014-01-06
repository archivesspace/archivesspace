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
      ASpaceImport::Utils.get_property_type(a.class.schema['properties']['title']).should eq([:string, nil])
      ASpaceImport::Utils.get_property_type(a.class.schema['properties']['subjects']).should eq([:record_ref_list, 'subject'])
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
      expect(a_parent.uri).to_not eq(old_uri)

      a1 = ASpaceImport::Utils.update_record_references(a1.to_hash(:raw), {old_uri => a_parent.uri})

      expect(a1['parent']['ref']).to eq(a_parent.uri)
      expect(a2['parent']['ref']).to_not eq(a_parent.uri)
    end
  end

end
