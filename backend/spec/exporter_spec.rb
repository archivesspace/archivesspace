# encoding: utf-8
require 'spec_helper'

describe "ASpaceExport" do
  describe "::get_serializer_for" do
    let(:ead_model) do
      obj = create(:json_resource)
      obj.repository = { 'ref' => '/repositories/1' }
      tree = {'children' => []}
      opts = { ead3: true }
      EADModel.new(obj, tree, opts)
    end

    it "does not raise error" do
      opts = {}
      expect { ASpaceExport.get_serializer_for(ead_model, opts) }.not_to raise_error
    end

    it "returns EAD3Serializer when specified in opts" do
      opts = { serializer: :ead3 }
      serializer = ASpaceExport.get_serializer_for(ead_model, opts)
      expect(serializer).to be_a(EAD3Serializer)
    end
  end

  describe "EADModel include_uris?" do
    let(:ead_model) do
      obj = create(:json_resource)
      obj.repository = { 'ref' => '/repositories/1' }
      tree = {'children' => []}
      EADModel.new(obj, tree, parameters)
    end

    context 'when the include_uris parameter is not provided' do
      let(:parameters) do
        {}
      end

      it "defaults include_uris to true" do
        expect(ead_model.include_uris?).to eq true
      end
    end

    context 'when the provided include_uris is nil' do
      let(:parameters) do
        {
          include_uris: nil
        }
      end

      it "defaults include_uris to true" do
        expect(ead_model.include_uris?).to eq true
      end
    end

    context 'when the provided include_uris is false' do
      let(:parameters) do
        {
          include_uris: false
        }
      end

      it "sets include_uris to false" do
        expect(ead_model.include_uris?).to eq false
      end
    end

    context 'when the provided include_uris is true' do
      let(:parameters) do
        {
          include_uris: true
        }
      end

      it "sets include_uris to true" do
        expect(ead_model.include_uris?).to eq true
      end
    end
  end
end
