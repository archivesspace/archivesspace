module ASpaceImport
  class Importer
    include JSONModel
    @@importers = {}

    # @return [Fixnum] the number of importers that have been loaded

    def self.importer_count
      @@importers.length
    end


    def self.list
      puts "The following importers are available"
      @@importers.each do |i, klass|
        puts "\t #{klass.name} \t #{klass.profile}"
      end
    end

    # @param options [Hash] runtime options passed into the importer
    # @return [Object] an instance of the selected importer
    # @raise [StandardError] if the class of the selected importer doesn't pass the usability test

    def self.create_importer(options)
      i = @@importers[options[:importer].to_sym]
      if i.usable
        i.new options
      else
        raise StandardError.new("Unusable importer or importer not found for: #{name}")
      end
    end
    
    def self.destroy_importers
      @@importers = {}
    end

    # @param name [Symbol] the key declared by importer being loaded
    # @param superclass [Const] a superfluous param in all likelihood
    # @param block [Block] the data-processing and self-describing methods defined by the importer, the meat of the importer
    # @return [Boolean]

    def self.importer(name, superclass = ASpaceImport::Importer, &block)
      if @@importers.has_key? name
        raise StandardError.new("Attempted to register #{name} a second time")
      else
        c = Class.new(superclass, &block)
        Object.const_set("#{name.to_s.capitalize}Importer", c)
        @@importers[name] = c
        true
      end
    end

    # @return [Boolean]

    def self.usable
      true
    end


    def initialize(opts = { })
      opts.each do |k,v|
        instance_variable_set("@#{k}", v)
      end
      @import_keys = []
      @goodimports = 0
      @badimports = 0
      @current = { }
      @stashed = { }
    end


    def report
      puts "#{@goodimports} records imported"
      # puts "#{@badimports} records failed to import"
    end


    def run
      raise StandardError.new("Unexpected error: run method must be defined by a subclass")
    end

  end
end

