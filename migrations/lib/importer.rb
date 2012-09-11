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
      puts "#{@badimports} records failed to import"
    end


    def run
      raise StandardError.new("Unexpected error: run method must be defined by a subclass")
    end

    # If the import user does nothing, the repository will be the most recently opened repository, 
    # or else the repository set when the importer was initialized

    # def get_import_opts
    #   opts = { }
    #   if @current[:repository]
    #     opts.merge!({ :repo_id => @current[:repository].last })
    #   elsif @repo_key
    #     # TODO - change the @repo_key option to @repo_code and do a lookup
    #     opts.merge!({ :repo_id => @repo_key })
    #     @current[:repository]= [@repo_key]
    #   end
    #   opts
    # end

    # # Makes inferences and adjustments to a Hash before it gets converted to a JSONModel object
    #  # @param type [Symbol] the schema type
    #  # @param hsh [Hash] the hash sent by the importer via an open_new or add_new directive
    # 
    #  def contextualize(type, hsh)
    #    # TODO - Can JSONModel tell me if a context element is relevant for my type?
    #    puts @current.inspect if $DEBUG
    #    if type == :archival_object and !hsh.has_key?(:resource) and @current[:resource]
    #      # TODO - Can JSONModel return this URL if I give it the Resource Key?
    #      hsh.merge!( { :resource => "/repositories/#{ @current[:repository].last }/resources/#{ @current[:resource].last }" } )
    #    end
    #    if type == :archival_object and !hsh.has_key?(:parent) and @current[:archival_object].respond_to?('length') and @current[:archival_object].length > 0
    #      # TODO - Ditto
    #      hsh.merge!( { :parent => "/repositories/#{ @current[:repository].last }/archival_objects/#{ @current[:archival_object].last }"})
    #    end
    #    return hsh
    #  end
    # 
    #  # Switch contexts
    # 
    #  def open(type, key)
    #    # TODO - This needs to be validated against the backend or a
    #    # list of successful imports
    #    @current[type].push(key)
    #  end
    # 
    #  # Add something to ASpace, but don't add it to the context
    #  
    #  def add_new(type, property, value)
    #    @json_queue.last
    #    hsh = contextualize(type, hsh)
    #    key = _import(type, hsh, opts)
    #    return key
    #  end
    # 
    #  def current (type)
    #    return @current[type].last
    #  end
    # 
    #  def last_succeeded?
    #    return true if @last_succeeded == true
    #    return false if @last_succeeded == false
    #  end
    # 
    #  # Stash a metadata field while stream-parsing
    #  # @params key [symbol] the field key
    #  def stash(k, v)
    #    @stashed[k] = Array.new unless @stashed[k].respond_to?('push')
    #    @stashed[k].push(v)
    #  end
    # 
    #  # @see stash
    # 
    #  def grab(k)
    #    @stashed[k].pop
    #  end
    # 
    #  def _import(type, hsh, opts = {})
    #    begin
    #      raise ArgumentError.new("Don't know how to import a #{type}, mate!") unless JSONModel(type)
    #      raise ArgumentError.new("Expected a Hash got #{hsh}") unless hsh.is_a?(Hash)
    #      puts "Importing #{hsh.to_json}" if @verbose
    #      strict_mode(true)
    #      puts "Hash: #{hsh.to_s}" if $DEBUG
    #      jo = JSONModel(type).from_hash(hsh)
    #      if @dry
    #        puts "(Not) Saving #{jo.to_s}";
    #        saved_key = 999
    #      else
    #        saved_key = jo.save( opts )
    #      end
    #      if saved_key != nil and saved_key != 0
    #        @goodimports += 1
    #        @last_succeeded = true
    #        return saved_key
    #      else
    #        @badimports += 1
    #        @last_succeeded = false
    #      end
    #      
    #    rescue ArgumentError => e
    #      if @relaxed
    #        puts "Warning: #{e.message}"
    #        @badimports += 1
    #      else
    #        raise e
    #      end
    # 
    #    rescue Exception => e
    #      if @relaxed
    #        puts "Warning: #{e.message}"
    #        @badimports += 1
    #      else
    #        raise e
    #      end
    #    end
    #  end
  end
end

