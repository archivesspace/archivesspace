require_relative 'lib/parse_queue'
class Converter

  class ConverterMappingError < StandardError; end

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


  def self.register_converter(subclass)
    @converters ||= []

    # Add the most recently created subclass to the beginning of the list so we
    # give it preference when searching.
    @converters.unshift(subclass)
  end


  def self.inherited(subclass)
    # We name Converter explicitly so that subclasses of subclasses still get
    # registered at the top-most level.
    Converter.register_converter(subclass)
  end


  # List all available import types.  Subclasses have the option of hiding
  # certain import types that they actually support (for example, for
  # suppressing imports that exist to support a plugin or user script, but
  # shouldn't be shown to end users)
  def self.list_import_types(show_hidden = false)
    seen_types = {}

    Array(@converters).map {|converter|
      converter.import_types(show_hidden).map {|import|
        # Plugins might define their own converters that replace the standard
        # ones.  Only show one instance of each importer.
        if seen_types[import[:name]]
          nil
        else
          seen_types[import[:name]] = true
          import
        end
      }
    }.flatten(1).compact
  end


  def self.for(type, input_file)
    Array(@converters).each do |converter|
      converter = converter.instance_for(type, input_file)
      return converter if converter
    end

    raise ConverterNotFound.new("No suitable converter found for #{type}")
  end

end
