# encoding: utf-8
require 'spec_helper'

describe "ASpaceExport" do

  describe "::get_serializer_for" do

    let(:ead_model) do
      obj = create(:json_resource)
      obj.repository = { 'ref' => '/repositories/1' }
      tree = {'children' => []}
      opts = { ead3: true }
      EADModel.new(obj,tree,opts)
    end

    it "does not raise error" do
      opts = {}
      expect{ ASpaceExport.get_serializer_for(ead_model, opts) }.to_not raise_error
    end

    it "returns EAD3Serializer when specified in opts" do
      opts = { serializer: :ead3 }
      serializer = ASpaceExport.get_serializer_for(ead_model, opts)
      expect(serializer).to be_a(EAD3Serializer)
    end

  end

end
