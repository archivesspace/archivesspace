module ASpaceExport
  
  @@initialized = false
  
  def self.init            
    @@serializers = {}
    Dir.glob(File.dirname(__FILE__) + '/../serializers/*', &method(:load))
    @@initialized = true    
  end
  
  def self.initialized?
    @@initialized
  end
  
  # Define or get a serializer
  def self.serializer(name, superclass = ASpaceExport::Serializer, &block)
    if @@serializers.has_key? name and block_given?
      Log.warn("Registered a serializer -- #{name} -- more than once")
    end
    
    unless block_given? or @@initialized
      self.init
    end
    
    if block_given?
      c = Class.new(superclass, &block)
      Object.const_set("#{name.to_s.capitalize}Serializer", c)
      @@serializers[name] = c
      true
    elsif @@serializers[name] == nil
      raise StandardError.new("Can't find a serializer named #{name}")
    else
      @@serializers[name].new
    end
  end

  # Abstract serializer class
  class Serializer
    
    def initialize
      @repo_id = Thread.current[:repo_id] ||= 1
    end
    
    def repo_id=(id)
      @repo_id = id
    end

    # Serializes an ASModel object
    def serialize(object) end  
  end    
end
      
      