require_relative 'spec_helper'
require_relative '../app/lib/index_batch'

describe "index batch" do
  before(:each) do
    @batch = IndexBatch.new
  end
  describe "initialize" do
    it "initializes @bytes to 2" do
      expect(@batch.instance_variable_get(:@bytes)).to eq(2)
    end
    it "initializes @record_count to 0" do
      expect(@batch.instance_variable_get(:@record_count)).to eq(0)
    end
    it "initializes @closed to false" do
      expect(@batch.instance_variable_get(:@closed)).to be false
    end
    it "initializes @filestore with filename that includes 'index_batch'" do
      file = @batch.instance_variable_get(:@filestore)
      expect(file.path).to include("index_batch")
    end
    it "initializes index batch file with \"[\\n\"" do
      file = @batch.instance_variable_get(:@filestore)
      file.rewind
      expect(file.read).to eq("[\n")
    end
  end
  describe "close" do
    describe "if @closed is false" do
      it "sets @closed to true and closes the batch file" do
        expect(@batch.instance_variable_get(:@closed)).to be false
        @batch.close
        expect(@batch.instance_variable_get(:@closed)).to be true
      end
      it "writes \"]\\n\" for batch file" do
        @batch.close
        file = @batch.instance_variable_get(:@filestore)
        file.rewind
        expect(file.read).to eq("[\n]\n")
      end
    end
    describe "if @closed is true" do
      it "does nothing to the batch file" do
        file = @batch.instance_variable_get(:@filestore)
        file.rewind
        expect(file.read).to eq("[\n")
        @batch.instance_variable_set(:@closed, true)
        @batch.close
        file = @batch.instance_variable_get(:@filestore)
        file.rewind
        expect(file.read).to eq("[\n")
      end
    end
  end
  describe "write" do
    it "writes expected string to the batch file" do
      @batch.write("HELLO")
      file = @batch.instance_variable_get(:@filestore)
      file.rewind
      expect(file.read).to eq("[\nHELLO")
    end
  end
  describe "<<" do
    it "writes a doc to the batch file" do
      doc = {}
      doc['id'] = "ID"
      doc['uri'] = "URI"
      expect(@batch.instance_variable_get(:@record_count)).to eq(0)
      @batch << doc
      file = @batch.instance_variable_get(:@filestore)
      file.rewind
      expect(file.read).to eq("[\n{\"id\":\"ID\",\"uri\":\"URI\"}\n")
    end
    it "increments record count for each added doc" do
      doc = {}
      doc['id'] = "ID"
      doc['uri'] = "URI"
      expect(@batch.instance_variable_get(:@record_count)).to eq(0)
      @batch << doc
      expect(@batch.instance_variable_get(:@record_count)).to eq(1)
      doc = {}
      doc['id'] = "ID2"
      doc['uri'] = "URI2"
      @batch << doc
      expect(@batch.instance_variable_get(:@record_count)).to eq(2)
    end
  end
  describe "rewind" do
    it "rewinds the batch file and reads the initial \"[\\n\"" do
      doc = {}
      doc['id'] = "ID"
      doc['uri'] = "URI"
      expect(@batch.instance_variable_get(:@record_count)).to eq(0)
      @batch << doc
      expect(@batch.instance_variable_get(:@record_count)).to eq(1)
      expect(@batch.rewind).to eq("[\n")
    end
  end
  describe "map" do
    it "converts from json to array" do
      doc = {}
      doc['id'] = "ID"
      doc['uri'] = "URI"
      doc['title'] =  "Test record 1"
      @batch << doc
      doc = {}
      doc['id'] = "ID2"
      doc['uri'] = "URI2"
      doc['title'] =  "Test doc 1"
      @batch << doc
      result = @batch.map { | i |
        "\"#{i['id']}\"" if i['title'].include?("Test")
      }
      expect(result).to be_an(Array)
    end
  end
  describe "each" do
    it "creates batch index for specific docs" do
      doc = {}
      doc['id'] = "ID"
      doc['uri'] = "URI"
      doc['title'] =  "Test record 1"
      @batch << doc
      doc = {}
      doc['id'] = "ID2"
      doc['uri'] = "URI2"
      doc['title'] =  "Test doc 1"
      @batch << doc
      doc = {}
      doc['id'] = "ID3"
      doc['uri'] = "URI3"
      doc['title'] =  "Test doc 2"
      @batch << doc
      result = @batch.each { | i |
        "\"#{i['id']}\"" if i['title'].include?("doc")
      }
      expect(@batch.instance_variable_get(:@record_count)).to eq(3)
      expect(@batch.instance_variable_get(:@closed)).to be false
      expect(@batch.instance_variable_get(:@bytes)).to eq(148)
    end
  end
  describe "to_json_stream" do
    it "opens batch file for streaming" do
      doc = {}
      doc['id'] = "ID"
      doc['uri'] = "URI"
      doc['title'] =  "Test record 1"
      @batch << doc
      doc = {}
      doc['id'] = "ID2"
      doc['uri'] = "URI2"
      doc['title'] =  "Test doc 1"
      @batch << doc
      expect(@batch.to_json_stream).to be_an(File)
    end
  end
  describe "byte_count" do
    it "returns the correct byte count" do
      doc = {}
      doc['id'] = "ID"
      doc['uri'] = "URI"
      doc['title'] =  "Test record 1"
      @batch << doc
      expect(@batch.byte_count).to eq(50)
      doc = {}
      doc['id'] = "ID2"
      doc['uri'] = "URI2"
      doc['title'] =  "Test doc 1"
      @batch << doc
      expect(@batch.byte_count).to eq(99)
    end
  end
  describe "concat" do
    it "concatenates docs" do
      doc = {}
      doc['id'] = "ID"
      doc['uri'] = "URI"
      doc['title'] =  "Test record 1"
      @batch << doc
      docs = []
      doc = {}
      doc['id'] = "ID2"
      doc['uri'] = "URI2"
      doc['title'] =  "Test doc 1"
      docs << doc
      doc = {}
      doc['id'] = "ID3"
      doc['uri'] = "URI3"
      doc['title'] =  "Test doc 2"
      docs << doc
      @batch.concat(docs)
      expect(@batch.instance_variable_get(:@record_count)).to eq(3)
    end
  end
  describe "empty?" do
    it "returns true if empty" do
      expect(@batch.empty?).to be true
    end
    it "returns false if not empty" do
      doc = {}
      doc['id'] = "ID"
      doc['uri'] = "URI"
      doc['title'] =  "Test record 1"
      @batch << doc
      expect(@batch.empty?).to be false
    end
  end
  describe "length" do
    it "returns length based on @record_count" do
      doc = {}
      doc['id'] = "ID"
      doc['uri'] = "URI"
      expect(@batch.length).to eq(@batch.instance_variable_get(:@record_count))
      @batch << doc
      expect(@batch.length).to eq(@batch.instance_variable_get(:@record_count))
      doc = {}
      doc['id'] = "ID2"
      doc['uri'] = "URI2"
      @batch << doc
      expect(@batch.length).to eq(@batch.instance_variable_get(:@record_count))
    end
  end
  describe "destroy" do
    it "cleans up by geting rid of the batch file" do
      doc = {}
      doc['id'] = "ID"
      doc['uri'] = "URI"
      @batch << doc
      doc = {}
      doc['id'] = "ID2"
      doc['uri'] = "URI2"
      @batch << doc
      expect(@batch.empty?).to be false
      @batch.destroy
      expect(@batch.instance_variable_get(:@filestore).closed?).to be true
    end
  end
end
