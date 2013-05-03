require 'nokogiri'
require_relative 'utils'

module ASpaceImport
  module XML
    module DOM

      module ClassMethods
        def configuration
          @configuration ||= self.configure
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end
      
      def configuration
        self.class.configuration    
      end
    
      def run

        @doc = Nokogiri::XML::Document.parse(IO.read(@input_file))
        @doc.remove_namespaces!
        
        configuration.each do |path, defn|
          object(path, defn)
        end

        @log.debug("Parse Queue State: #{parse_queue.inspect}")

        save_all
      end
      
      
      def object(path, defn)
        @context ||= [@doc]
        @context.last.xpath(path).each do |node|
          @context << node
          obj = ASpaceImport::JSONModel(defn[:obj]).new
          parse_queue << obj
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
      end
      
      
      def process_field(obj, key, value)
        
        # xpath => :field_name
        if key.is_a?(String) && value.is_a?(Symbol)
          @context.last.xpath(key).each do |node|
            if obj[value].is_a?(Array)
              obj[value] << node.inner_text
            else
              obj[value] = node.inner_text
            end
          end
        # xpath => Proc 
        elsif key.is_a?(String) && value.is_a?(Proc)
          @context.last.xpath(key).each do |node|
            value.call(obj, node)
          end
        # xpath => sub record definition
        elsif key.is_a?(String) && value.is_a?(Hash)
          object(key, value) do |sub_obj|
            if value[:rel].is_a?(Proc)
              value[:rel].call(obj, sub_obj)
            else
              property_type = ASpaceImport::Utils.get_property_type(obj.class.schema['properties'][value[:rel].to_s])
              filtered_value = ASpaceImport::Utils.value_filter(property_type[0]).call(sub_obj)
              obj[value[:rel]] << filtered_value
            end
          end

        else
          raise "Don't know how to handle a (#{field.class.name}) => (#{defn.class.name}) situation"
        end
      end      
    end
  end
end
    
    
    