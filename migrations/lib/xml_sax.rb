require 'nokogiri'
require_relative 'record_proxy'
require_relative 'utils'

module ASpaceImport
  module XML
    module SAX
      
      module ClassMethods
        def with(node_name, &block)
          handler_name = "_#{node_name}"
          define_method(handler_name, block)
        end
        
        def ensure_configuration
          @configured ||= false
          unless @configured
            self.configure
          end  
        end
        
      end
      
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      def method_missing(*args)
      end


      def run
        @reader = Nokogiri::XML::Reader(IO.read(@input_file))
        @context = []
        @context_nodes = {}

        self.class.ensure_configuration

        @reader.each do |node|

          case node.node_type

          when 1
            handle_opener(node)        
          when 3
            handle_text(node)
          when 15
            handle_closer(node)
          end
        end

        @log.debug("Parse Queue State: #{parse_queue.inspect}")

        save_all

        ASpaceImport::RecordProxy.undischarged.each do |prox|
          @log.debug("Undischarged: #{prox.to_s}")
        end
      end
    
    
      def handle_opener(node)

         @node_name = node.name
         @node_depth = node.depth
         self.send("_#{node.name}", node)
      end


      def handle_text(node)    
        ASpaceImport::RecordProxy.discharge_proxy(:text, node.value)
      end


      def handle_closer(node)

        if @context_nodes[node.name] && @context_nodes[node.name][node.depth]
          @context_nodes[node.name][node.depth].reverse.each do |type|
            close_context(type)
          end
          @context_nodes[node.name].delete_at(node.depth)
        end
      end     


      def open_context(type)

        obj = ASpaceImport::JSONModel(type).new

        @context.push(type)
        parse_queue.push(obj)

        @context_nodes[@node_name] ||= []
        @context_nodes[@node_name][@node_depth] ||= []
        @context_nodes[@node_name][@node_depth] << type
      end


      def close_context(type)
        @log.debug("Close context <#{type}>")
        if parse_queue.last.jsonmodel_type != type.to_s
          raise "Unexpected Object Type in Queue: Expected #{type} got #{parse_queue.last.jsonmodel_type}"
        end

        ASpaceImport::RecordProxy.discharge_proxy(type, parse_queue.last)

        @context.pop
        parse_queue.pop
      end

      # Schedule retrieval from the next text node
      # to show up
      def inner_text
        ASpaceImport::RecordProxy.get_proxy_for(:text)
      end


      def set_property(obj = :context, property, value)

        if obj.nil?
          raise "Trying to set property #{property} on nil object"
        end

        if property.nil?
          @log.warn("Can't set <#{obj.class.record_type}> <#{property}>: nil value")
          return false
        end

        obj = context_obj if obj == :context

        @log.debug("Setting <#{obj.jsonmodel_type}> <#{property}> using <#{value.inspect}> (unfiltered)")

        begin
          property_type = ASpaceImport::Utils.get_property_type(obj.class.schema['properties'][property.to_s])
        rescue NoMethodError
          raise "Having some trouble finding a property <#{property}> on a <#{obj.class.record_type}> object"
        end

        if value.is_a?(ASpaceImport::RecordProxy)
          value.on_discharge(self, :set_property, obj, property)
        else
          if value.nil?
            @log.warn("Given a nil value for <#{obj.class.record_type}><#{property}>")
          else
            filtered_value = ASpaceImport::Utils.value_filter(property_type[0]).call(value)
            @log.debug("Filtered Value: #{filtered_value.inspect}")
            if property_type[0].match /list$/
              val_array = obj.send("#{property}").push(filtered_value)
              obj.send("#{property}=", val_array)
            else
              if obj.send("#{property}")
                @log.warn("Setting a property that has already been set")
              end
              obj.send("#{property}=", filtered_value)
            end
          end
        end
      end


      # Since it won't do to push subrecords into
      # parent records until the subrecords are complete,
      # a proxy can be assigned instead, and the proxy 
      # will discharge the JSON subrecord once it is complete

      def proxy(record_type = context)
        ASpaceImport::RecordProxy.get_proxy_for(record_type)
      end


      def ancestor(*types)
        queue_offset = @context_nodes.has_key?(@node_name) ? -2 : -1

        obj = parse_queue[0..queue_offset].reverse.find { |o| types.map {|t| t.to_s }.include?(o.class.record_type)}          
        obj
      end


      def getat(node, attribute)
        att_pair = node.attributes.find {|a| a[0] == attribute}
        if att_pair.nil?
          nil
        else
          att_pair[1].downcase
        end
      end 


      def context
        @context.last
      end


      def context_obj
        parse_queue.last
      end
    
    end
  end
end
    
    
    