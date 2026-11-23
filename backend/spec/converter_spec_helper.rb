require 'spec_helper'
require 'forwardable'

def convert(path_to_some_xml, import_events = false, import_subjects = true)
  converter = my_converter.new(path_to_some_xml)

  if converter.respond_to?(:set_import_options)
    converter.set_import_options({:import_events   => import_events,
                                  :import_subjects => import_subjects})
  end

  converter.run
  json = JSON(IO.read(converter.get_output_path))

  json
end


def get_tempfile_path(src)
  tmp = ASUtils.tempfile("doc-#{Time.now.to_i}")
  tmp.write(src)
  tmp.flush

  $icky_hack_to_avoid_gc ||= []
  $icky_hack_to_avoid_gc << tmp

  tmp.path
end

# Usage example:
# converter = TestConverter.instance_for(EAD3Converter, xml_to_test)
# converter << ASpaceImport::JSONModel(:resource).new
# converter.run
# expect(converter.records.resource.title).to eq("my title")
class TestConverter
  attr_accessor :record_batch, :records

  class ConvertedRecords
    extend Forwardable
    def_delegators :@records, :find, :select, :[], :map

    def initialize(records = [])
      @records = records
    end

    %w(resource archival_object digital_object top_container agent_person).each do |type|
      define_method(type) do |index = 0|
        @records.select {|r| r.jsonmodel_type == type }[index]
      end

      define_method("#{type}s") do
        @records.select {|r| r.jsonmodel_type == type }
      end
    end
  end

  def self.instance_for(converter_class, input)
    input_file = ASUtils.tempfile("test_converter_input")
    input_file.write(input)
    input_file.close
    converter = converter_class.new(input_file)
    test_converter = self.new(converter)
    test_converter
  end

  def initialize(converter)
    @records = []
    @converter = converter
    @record_batch = converter.instance_variable_get(:@batch)
  end

  def run
    @converter.run
    @record_batch.flush
    record_hashes = JSON.load_file(@record_batch.get_output_path)
    @records = ConvertedRecords.new(deep_jsonize(record_hashes))
  end

  private

  def deep_jsonize(hash)
    if hash.is_a?(Array)
      hash.map {|h| deep_jsonize(h) }
    elsif hash.is_a?(Hash) && hash.has_key?("jsonmodel_type")
      obj = JSONModel(hash["jsonmodel_type"].intern).from_hash(hash)
      obj.class.schema['properties'].each do |p, defn|
        if obj[p].is_a?(Hash) || obj[p].is_a?(Array)
          obj[p] = deep_jsonize(obj[p])
        end
      end
      obj
    else
      hash
    end
  end
end
