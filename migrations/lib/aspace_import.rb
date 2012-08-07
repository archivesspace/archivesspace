class ASpaceImporter
  include JSONModel
  @@importers = { }
  
  def self.importer_count
    @@importers.length
  end
  
  def self.list
    puts "The following importers are available"
    @@importers.each do |i, klass|
      puts "#{i} -- #{klass.name} -- #{klass.profile}"
    end
  end
  
  def self.create_importer options
    i = @@importers[options[:importer].to_sym]
    if i.usable
      i.new options
    else
      raise StandardError.new("Unusable importer or importer not found for: #{name}")
    end
  end
  
  def self.importer name, superclass=ASpaceImporter, &block
    if @@importers.has_key? name
      raise StandardError.new("Attempted to register #{name} a second time")
    else
      c = Class.new(superclass, &block)
      Object.const_set("#{name.to_s.capitalize}ASpaceImporter", c)
      @@importers[name] = c
      true
    end
  end
  
  def self.usable
    if !defined? self.profile
      return false
    elsif !method_defined? :run
      return false
    else
      return true
    end
  end
  
  def initialize opts={ } 
    opts.each do |k,v|
      instance_variable_set("@#{k}", v)
    end
    @import_keys = []
    @goodimports = 0
    @badimports = 0
    @last_succeeded = false
    @current = { }
  end
  
  def report
    puts "#{@goodimports} records imported"
    puts "#{@badimports} records failed to import"
  end
  
  def run
    raise StandardError.new("Unexpected error: run method must be defined by a subclass")
  end
  
  # If the import user does nothing, the repository will be the most recently opened repository. TODO - the initialize
  # procedure should use an optional run time argument to find and open the default repository

  def get_import_opts
    opts = { }
    if @current[:repository]
      opts.merge!( { :repo_id => @current[:repository] } )
    end
    return opts
  end
  
  def contextualize (type, hsh)
    # TODO - Can JSONModel tell me if a context element is relevant for my type?
    if type == :archival_object and !hsh.has_key?(:collection) and @current[:collection]
      # TODO - Can JSONModel return this URL if I give it the Collection Key?
      hsh.merge!( { :collection => "/repositories/#{ @current[:repository] }/collections/#{ @current[:collection] }" } )
    end
    if type == :archival_object and !hsh.has_key?(:parent) and @current[:archival_object]
      # TODO - Ditto
      hsh.merge!( { :parent => "/repositories/#{ @current[:repository] }/archival_objects/#{ @current[:archival_object] }"})
    end
    return hsh
  end
  
  # Switch contexts
  
  def open (type, key)
    # TODO - This needs to be validated against the backend or a 
    # list of successful imports
    @current[type] = key
  end
  
  # Add something to ASpace, but don't add it to the context
    
  def add_new (type, hsh)
    opts = get_import_opts
    hsh = contextualize(type, hsh)
    key = _import(type, hsh, opts)
    return key
  end
  
  # Add something to ASpace, and 'open' it
  
  def open_new (type, hsh)
    key = add_new(type, hsh)
    unless key.nil?
      @current[type] = key
    end
    return key
  end
  
  def current (type)
    return @current[type]
  end
  
  def last_succeeded?
    return true if @last_succeeded == true
    return false if @last_succeeded == false
  end
       
  def _import(type, hsh, opts = {})
    begin
      raise ArgumentError.new("Don't know how to import a #{type}, mate!") unless JSONModel(type)
      raise ArgumentError.new("Expected a Hash got #{hsh}") unless hsh.is_a?(Hash)
      puts "Importing #{hsh.to_json}" if @verbose
      strict_mode(true)
      jo = JSONModel(type).from_hash(hsh)
      saved_key = jo.save( opts )
      if saved_key != nil and saved_key != 0
        @goodimports += 1
        @last_succeeded = true
        return saved_key
      else
        @badimports += 1
        @last_succeeded = false
        return nil
      end
    rescue ArgumentError => e
      if @relaxed
        puts "Warning: #{e.message}"
        @badimports += 1
      else
        raise e
      end
      
    rescue Exception => e
      if @relaxed
        puts "Warning: #{e.message}"
        @badimports += 1
      else
        raise e
      end
    end
  end
end
