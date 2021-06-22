require 'nokogiri'
require_relative 'parse_queue'
require_relative 'utils'
require_relative 'jsonmodel_wrap'
require 'saxerator'

module ASpaceImport
  module XML
    module DOM

      module ClassMethods
        def configure
          @config ||= Config.new
          yield @config
        end


        def config
          @config
        end


        def make(type)
          yield ASpaceImport::JSONModel(type).new
        end


        def mix(hash1, hash2, hash3=nil)
          if hash3
            hash2 = mix(hash2, hash3)
          end
          hash1.merge(hash2) do |key, one, two|
            if one.is_a?(Hash) && two.is_a?(Hash)
              mix(one, two)
            elsif one.is_a?(Proc) && two.is_a?(Proc)
              [one, two]
            elsif one.is_a?(Array) && two.is_a?(Proc)
              one << two
            else
              two
            end
          end
        end
      end


      def self.included(base)
        base.extend(ClassMethods)
      end


      def config
        self.class.config
      end


      def run
        if config.doc_frag_nodes.empty?
          @doc = Nokogiri::XML::Document.parse(IO.read(@input_file))
          @doc.remove_namespaces!

          config.mappings.each do |path, defn|
            object(path, defn)
          end
        else
          parser = Saxerator.parser(IO.read(@input_file)) do |config|
            config.output_type = :xml
            config.ignore_namespaces!
            config.strip_namespaces!
          end

          config.doc_frag_nodes.each do |break_node|
            parser.for_tag(break_node).each do |xml|
              @doc = xml
              @context = [@doc]
              config.mappings.each do |path, defn|
                object(path, defn)
              end
            end
          end
        end
      end


      def object(path, defn)
        @context ||= [@doc]
        @context.last.xpath(path).each do |node|
          @context << node
          obj = ASpaceImport::JSONModel(defn[:obj]).new
          @batch << obj
          defn[:map].each do |key, defn|
            process_field(obj, key, defn)
          end
          if defn[:defaults]
            defn[:defaults].each do |key, val|
              if obj[key].nil?
                obj[key] = val
              end
            end
          end
          yield obj if block_given?
          @context.pop
        end
        if @context.length == 1
          @batch.flush
        end
      end


      def process_field(obj, key, value)
        raise "Received a non-string mapping: #{key}" unless key.is_a?(String)

        # xpath => Array
        if value.is_a?(Array)
          value.each do |i|
            process_field(obj, key, i)
          end
        # xpath => :field_name
        elsif value.is_a?(Symbol)
          @context.last.xpath(key).each do |node|
            if obj[value].is_a?(Array)
              obj[value] << node.inner_text
            else
              obj[value] = node.inner_text
            end
          end
        # xpath => Proc
        elsif value.is_a?(Proc)
          @context.last.xpath(key).each do |node|
            value.call(obj, node)
          end
        # xpath => sub record definition
        elsif value.is_a?(Hash)
          object(key, value) do |sub_obj|
            if value[:rel].is_a?(Proc)
              value[:rel].call(obj, sub_obj)
            else
              property_def = obj.class.schema['properties'][value[:rel].to_s]
              if property_def.nil?
                raise Converter::ConverterMappingError.new("The converter maps '#{key}' to a bad target (property '#{value[:rel]}' on record_type '#{obj.jsonmodel_type}').")
              end

              property_type = ASpaceImport::Utils.get_property_type(property_def)
              filtered_value = ASpaceImport::Utils.value_filter(property_type[0]).call(sub_obj)
              obj[value[:rel]] << filtered_value
            end
          end

        else
          raise Converter::ConverterMappingError.new("Bad types in mapping: (#{key.class.name}) => (#{value.class.name})")
        end
      end


      class Config
        attr_reader :mappings
        attr_accessor :doc_frag_nodes

        def initialize
          @doc_frag_nodes = []
        end

        def init_map(hash)
          @mappings = hash
        end

        def [](arg)
          @mappings[arg]
        end

        def []=(arg, val)
          @mappings ||= {}
          @mappings[arg] = val
        end
      end
    end
  end
end
