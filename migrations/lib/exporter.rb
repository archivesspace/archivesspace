require 'jsonmodel'
require 'nokogiri'

module ASpaceExport
  
  @@initialized = false
  
  def self.init            
    @@serializers = {}
    @@models = {}
    Dir.glob(File.dirname(__FILE__) + '/../serializers/*', &method(:load))
    Dir.glob(File.dirname(__FILE__) + '/../models/*', &method(:load))
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
  
  # Define or get an export model
  def self.model(name, superclass = ASpaceExport::ExportModel, &block)
    if @@models.has_key? name and block_given?
      Log.warn("Registered a model -- #{name} -- more than once")
    end
    
    unless block_given? or @@initialized
      self.init
    end
    
    if block_given?
      c = Class.new(superclass, &block)
      Object.const_set("#{name.to_s.capitalize}ExportModel", c)
      @@models[name] = c
      true
    elsif @@models[name] == nil
      raise StandardError.new("Can't find a model named #{name}")
    else
      @@models[name]
    end
  end 

  # Abstract serializer class
  class Serializer
    
    def initialize
      @repo_id = Thread.current[:repo_id] ||= 1
      @builder = Nokogiri::XML::Builder.new
    end
    
    def repo_id=(id)
      @repo_id = id
    end
    
    # def set(instance_variable, value)
    #   self.instance_variable_set(instance_variable, value)
    # end

    # Serializes an ASModel object

    def serialize(object) end
    
    def insert(meth)

      old_kontext = @kontext.clone

      if self.respond_to?(meth) && @kontext[0].respond_to?(meth)
        if @kontext[0].send(meth).is_a?(Array)
          @kontext[0].send(meth).each do |mem|
            @kontext[0] = mem
            @kontext[1].send(meth) {
              self.send(meth)
            }
          end
        else            
          @kontext[0] = @kontext[0].send(meth)
          @kontext[1].send(meth) {
            self.send(meth)
          }
        end
      elsif @kontext[0].respond_to?(meth)
        values = *(@kontext[0].send(meth))
        values.each do |val|
          raise "oops #{val} is not a string" unless val.is_a?(String)
          @kontext[1].send(meth, val) unless val.nil?
        end
      else
        raise "Neither the serializer nor the data object responds to #{meth}"
      end

      @kontext = old_kontext
    end  
      

  end
  
  # Abstract Export Model class
  class ExportModel

    
    # Syntax for defining structure for an export model:
    # structure :name => name,
    #           :once => (children appearing once)
    #           :many => (children appearing more than once)
    #           (..TODO: attributes)
    # 
    
    # def self.struct
    #    @structure ||={}
    #    @structure
    #  end
    #  
    #  def self.attribute_groups
    #    @attribute_groups ||= {}
    #  end
    #  
    #  def self.structure(opts) 
    # 
    #    Log.debug("OPTS #{opts.inspect}")
    #    @structure ||= {}
    #    
    #    struct_owner = self
    #    
    #    klass = Object.const_set("Structural"+opts[:name].to_s.capitalize, Class.new)
    #    klass.instance_variable_set(:@structure, @structure)
    # 
    #    singles = opts[:once] || []
    #    multies = opts[:many] || []
    # 
    #    klass.class_eval do
    # 
    #      attr_accessor *(singles + multies).reject{|i| i.nil?}
    #        
    #      singles.each do |child|
    #        define_method(child) do
    #          if (iv = instance_variable_get("@"+child.to_s))
    #            iv
    #          elsif (structural = struct_owner.struct[child])
    #            instance_variable_set("@"+child.to_s, structural.new)  
    #          else
    #            instance_variable_set("@"+child.to_s, String.new)
    #          end
    #        end
    #      end
    #    
    #      multies.each do |child|
    #        define_method(child) do
    #          if (iv = instance_variable_get("@"+child.to_s))
    #            iv
    #          elsif (structural = struct_owner.struct[child])
    #            # instance_variable_set("@"+child.to_s, [structural.new])
    #            instance_variable_set("@"+child.to_s, StructArray.new(structural))
    #          else
    #            instance_variable_set("@"+child.to_s, StructArray.new(String))
    #          end
    #        end
    #      end
    # 
    #    end
    # 
    #    @structure[opts[:name]] = klass
    #  end
    #  
    #  
    #  def self.bild(name)
    #    
    #    if @structure.has_key?(name)
    #      @structure[name].new
    #    else
    #      nil
    #    end
    #  end
    
    
    def initialize
    end


    def apply_map(obj, map)
      map.each do |as_field, handler|
        
        fieldable = [as_field].flatten.reject { |asf| !obj.respond_to?(asf) }
        
        next if fieldable.empty? # probably a relationship
        
        handler_args = fieldable.map {|f| obj.send(f) }

        
        [handler].flatten.each {|h| self.send(h, *handler_args)  }

      end
    end
    
    
    # def keyed_attributes(key, vals)
    #   hsh = {}
    #   self.class.attribute_groups[key].each_with_index {|s,i| hsh[s] = vals[i]}
    #   hsh
    # end
    
  end

  class Nokogiri::XML::Builder
    alias :old_method_missing :method_missing
    
    def method_missing(m, *args, &block)
  
      @sticky_ns ||= nil
      @ns = @sticky_ns if @sticky_ns
      
  
      old_method_missing(m, *args, &block)
  
    end
  end  

    
end
      
      
