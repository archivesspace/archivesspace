class Converter

  class ConverterNotFound < StandardError; end

  def initialize(input_file)
    @input_file = input_file
    @batch = ASpaceImport::RecordBatch.new
  end


  def get_output_path
    @batch.get_output_path
  end


  def remove_files
    File.unlink(get_output_path)
  end


  def self.inherited(subclass)
    @converters ||= []

    # Add the most recently created subclass to the beginning of the list so we
    # give it preference when searching.
    @converters.unshift(subclass)
  end


  def self.for(type, input_file)
    Array(@converters).each do |converter|
      converter = converter.instance_for(type, input_file)
      return converter if converter
    end

    raise ConverterNotFound.new("No suitable converter found for #{type}")
  end


end
