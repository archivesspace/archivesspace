require_relative 'lib/parse_queue'

#
# `Converter` is an interface used to implement new importer types.  To
# implement your own converter, create a subclass of this class and implement
# the "IMPLEMENT ME" methods marked below.
#
class Converter

  # Implement this in your Converter class!
  #
  # Returns descriptive metadata for the import type(s) implemented by this
  # Converter.
  def self.import_types(show_hidden = false)
    raise NotImplementedError.new

    # Example:
    [
     {
       :name => "my_import_type",
       :description => "Description of new importer"
     }
    ]
  end

  # Implement this in your Converter class!
  #
  # If this Converter will handle `type` and `input_file`, return an instance.
  def self.instance_for(type, input_file)
    raise NotImplementedError.new

    # Example:
    if type == "my_import_type"
      self.new(input_file)
    else
      nil
    end
  end

  # Implement this in your Converter class!
  #
  # Process @input_file and load records into @batch.
  def run
    raise NotImplementedError.new
  end


  ##
  ## That's it!  Other implementation bits follow...

  class ConverterMappingError < StandardError; end

  class ConverterNotFound < StandardError; end

  def initialize(input_file)
    @input_file = input_file
    @batch = ASpaceImport::RecordBatch.new
    @import_options = {}
  end


  def get_output_path
    @batch.get_output_path
  end


  # forcibly remove files in the event of an interruption
  def remove_files
    @batch.each_open_file_path do |path|
      3.times do |i|
        begin
          File.unlink(path)
          break
        rescue Errno::EACCES # sometimes windows does not like this. let's wait and retry.
          sleep(1) # just in case it's open by something else..
          next unless i == 2
          $stderr.puts "Cannot remove #{path}...giving up."
        end
      end
    end
  end


  def import_options
    self.class.import_options
  end


  def self.import_options
    @import_options
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


  def self.for(type, input_file, opts = {})
    Array(@converters).each do |converter|
      converter = converter.instance_for(type, input_file)

      if converter
        if converter.respond_to?(:set_import_options)
          import_events = opts[:import_events]
          import_subjects = opts[:import_subjects]
          import_repository = opts[:import_repository]

          unless [import_events, import_subjects, import_repository].all?(&:nil?)
            converter.set_import_options({:import_events   => import_events,
                                          :import_subjects => import_subjects,
                                          :import_repository => import_repository})
          end
        end

        return converter
      end
    end

    raise ConverterNotFound.new("No suitable converter found for #{type}")
  end

end
