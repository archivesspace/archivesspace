require 'jsonmodel'
require 'nokogiri'
require 'i18n'
require_relative 'utils'

module ASpaceExport

  @@initialized = false

  def self.init
    @@serializers = {}
    @@models = {}
    Dir.glob(File.dirname(__FILE__) + '/../serializers/*.rb', &method(:load))
    Dir.glob(File.dirname(__FILE__) + '/../models/*.rb', &method(:load))

    I18n.load_path += ASUtils.find_locales_directories(File.join("enums", "#{AppConfig[:locale]}.yml"))
    @@initialized = true
  end
  
  
  def self.reload(exporter_key)
    @@serializers[exporter_key] = nil
    @@models[exporter_key] = nil
    Dir.glob(File.dirname(__FILE__) + "/../serializers/#{exporter_key.to_s}.rb", &method(:load))
    Dir.glob(File.dirname(__FILE__) + "/../models/#{exporter_key.to_s}.rb", &method(:load))
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

    # Serializes an ASModel object
    def serialize(object) end


    # use a serializer to embed wrapped data
    # for example, MODS data wrapped in METS
    def self.with_namespace(prefix, xml)
      ns = xml.doc.root.namespace_definitions.find{|ns| ns.prefix == prefix}
      xml.instance_variable_set(:@sticky_ns, ns)
      yield 
      xml.instance_variable_set(:@sticky_ns, nil)
    end
  end


  class ExportModel
    def initialize
    end

    def apply_map(obj, map, opts = {})
      fields_to_ignore = opts[:ignore] ||= []

      map.each do |as_field, handler|
        next if fields_to_ignore.include? as_field

        fieldable = [as_field].flatten.reject { |asf| !obj.respond_to?(asf) }

        next if fieldable.empty? # probably a relationship

        handler_args = fieldable.map {|f| obj.send(f) }
        [handler].flatten.each {|h| self.send(h, *handler_args)  }
      end
    end
  end

  # Contrive Nokogiri to remember namespaces
  class Nokogiri::XML::Builder
    alias :old_method_missing :method_missing

    def method_missing(m, *args, &block)
      @sticky_ns ||= nil
      @ns = @sticky_ns if @sticky_ns

      old_method_missing(m, *args, &block)
    end
  end
end


