require 'jsonmodel'
require 'nokogiri'
require 'i18n'
require_relative 'utils'
require_relative 'export_helpers'
require_relative 'streaming_xml'

module ASpaceExport

  @@initialized = false

  def self.init
    return if @@initialized

    @@serializers = []
    @@models = []
    Dir.glob(File.dirname(__FILE__) + '/../serializers/*.rb', &method(:require))
    Dir.glob(File.dirname(__FILE__) + '/../models/*.rb', &method(:require))

    @@initialized = true
  end


  def self.register_serializer(serializer_class)
    @@serializers << serializer_class
  end

  # Define or get a serializer
  def self.serializer(name, &block)

    if block_given?
      serializer = Class.new(Serializer, &block)
      serializer.instance_variable_set(:@serializer_for, name)
      serializer.class_eval do
        def self.serializer_for?(name_queried)
          name_queried == @serializer_for
        end
      end

      register_serializer(serializer)
    else
      @@serializers.each do |serializer|
        return serializer if serializer.serializer_for? name
      end

      raise SerializerNotFoundError.new("Can't find a serializer for: #{name}")
    end
  end


  def self.register_model(model_class)
    @@models << model_class
  end


  # Define or get an export model
  def self.model(name, &block)

    if block_given?
      model = Class.new(ExportModel, &block)
      model.instance_variable_set(:@model_for, name)
      model.class_eval do
        def self.model_for?(name_queried)
          name_queried == @model_for
        end
      end

      register_model(model)
    else
      @@models.each do |model|
        return model if model.model_for? name
      end

      raise ExportModelNotFoundError.new("Can't find a model for: #{name}")
    end
  end


  def self.get_serializer_for(model, opts)
    key = if opts[:serializer]
            opts[:serializer]
          else
            model.class.instance_variable_get(:@model_for)
          end

    serializer(key).new
  end


  def self.serialize(model, opts = {})
    s = get_serializer_for(model, opts)
    s.serialize(model, opts)
  end


  def self.stream(model, opts = {})
    s = get_serializer_for(model, opts)
    s.stream(model)
  end


  class Serializer

    def self.inherited(subclass)
      ASpaceExport.register_serializer(subclass)
    end


    def self.serializer_for(name)
      @serializer_for = name
    end


    def self.serializer_for?(name)
      @serializer_for == name
    end

    # use a serializer to embed wrapped data
    # for example, MODS data wrapped in METS
    def self.with_namespace(prefix, xml)
      ns = xml.doc.root.namespace_definitions.find{|ns| ns.prefix == prefix}
      xml.instance_variable_set(:@sticky_ns, ns)
      yield
      xml.instance_variable_set(:@sticky_ns, nil)
    end
  end

  class SerializerNotFoundError < StandardError; end


  class ExportModel
    include ExportModelHelpers

    def self.inherited(subclass)
      ASpaceExport.register_model(subclass)
    end


    def self.model_for(name)
      @model_for = name
    end


    def self.model_for?(name)
      @model_for == name
    end


    def apply_map(obj, map, opts = {})
      fields_to_ignore = opts[:ignore] ||= []

      map.each do |as_field, handler|
        next if fields_to_ignore.include? as_field

        fieldable = [as_field].flatten.reject { |asf| !obj.respond_to?(asf) }

        next if fieldable.empty?

        handler_args = fieldable.map {|f| obj.send(f) }
        [handler].flatten.each {|h| self.send(h, *handler_args)  }
      end
    end
  end

  class ExportModelNotFoundError < StandardError; end

  # Help Nokogiri to remember namespaces
  class Nokogiri::XML::Builder
    alias :old_method_missing :method_missing

    def method_missing(m, *args, &block)
      @sticky_ns ||= nil
      @ns = @sticky_ns if @sticky_ns
      begin
        old_method_missing(m, *args, &block)
      rescue => e
        # this is a bit odd, but i would be better if the end-user gets the
        # error information in their export, rather than in their output.
        node = @doc.create_element( "aspace_export_error" )
        node.content = "ASPACE EXPORT ERROR : YOU HAVE A PROBLEM WITH YOUR EXPORT OF YOUR RESOURCE. THE FOLLOWING INFORMATION MAY HELP:
        \n #{e.message} \n #{e.backtrace.inspect}"
        @parent.add_child(node)
      end

    end
  end
end


