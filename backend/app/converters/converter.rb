class Converter

  class ConverterNotFound < StandardError; end

  def initialize(input_file)
    @input_file = input_file
    @batch = ASpaceImport::RecordBatch.new
  end


  def get_output_path
    @batch.get_output_path
  end


  def self.inherited(subclass)
    @converters ||= []
    @converters << subclass
  end


  def self.for(type, input_file)
    Array(@converters).each do |converter|
      converter = converter.instance_for(type, input_file)
      return converter if converter
    end

    raise ConverterNotFound.new("No suitable converter found for #{type}")
  end


end
