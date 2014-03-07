require 'nokogiri'
require_relative 'jsonmodel_wrap'
require_relative 'parse_queue'
require_relative 'record_proxy'
require_relative 'utils'

module ASpaceImport
  module XML
    module SAX

      module ClassMethods
        def with(path, &block)
          @sticky_nodes ||= {}
          parts = path.split("/").reverse
          handler_name = ""
          while parts.length > 1
            @sticky_nodes[parts.last] = true
            handler_name << "_#{parts.pop}"
          end

          handler_name << "_#{parts.pop}"

          define_method(handler_name, block)
        end

        def ensure_configuration
          @configured ||= false
          @stickies = []
          unless @configured
            self.configure
          end
        end

        def make_sticky?(node_name)
          @sticky_nodes[node_name] || false
        end

      end


      def self.included(base)
        base.extend(ClassMethods)
      end


      def method_missing(*args)
      end


      # Get a hold of Nokogiri's internal nodeQueue for the sake of being able
      # to clear it.  This might not be necessary in new versions of Nokogiri.
      def node_queue_for(reader)
        obj = reader.to_java
        nodeQueueField = obj.get_class.get_declared_field("nodeQueue")
        nodeQueueField.setAccessible(true)
        nodeQueueField.get(obj)
      end


      def run
        @reader = Nokogiri::XML::Reader(IO.read(@input_file))
        node_queue = node_queue_for(@reader)
        @contexts = []
        @context_nodes = {}
        @proxies = ASpaceImport::RecordProxyMgr.new
        @stickies = []
        # another hack for noko:
        @node_shadow = nil

        self.class.ensure_configuration

        @reader.each_with_index do |node, i|
          case node.node_type

          when 1
            # Nokogiri Reader won't create events for closing tags on empty nodes
            # https://github.com/sparklemotion/nokogiri/issues/928
            # handle_closer(node) if node.self_closing? #<--- don't do this it's horribly slow
            if @node_shadow && node.depth <= @node_shadow[1]
              handle_closer(@node_shadow)
            end
            handle_opener(node)
          when 3
            handle_text(node)
          when 15
            handle_closer(node)
          end

          # A gross hack.  Use Java Reflection to clear Nokogiri's node queue,
          # since otherwise we end up accumulating all nodes in memory.
          node_queue.set(i, nil)
        end
      end


      def handle_opener(node)
        @node_name = node.local_name
        @node_depth = node.depth
        @node_shadow = [node.local_name, node.depth]
        @node = node

        # constrained handlers, e.g. publication/date
        @stickies.each_with_index do |prefix, i|
          self.send("_#{@stickies[i..@stickies.length].join('_')}_#{@node_name}", node)
        end

        # unconstrained handlers, e.g., date
        self.send("_#{@node_name}", node)

        # config calls for constrained handlers on this path
        make_sticky(@node_name) if self.class.make_sticky?(@node_name)

        @node = nil
      end


      def handle_text(node)
        @proxies.discharge_proxy(:text, node.value)
      end


      def handle_closer(node)
        @node_shadow = nil
        node_info = node.is_a?(Array) ? node : [node.local_name, node.depth]
        if @context_nodes[node_info[0]] && @context_nodes[node_info[0]][node_info[1]]
          @context_nodes[node_info[0]][node_info[1]].reverse.each do |type|
            close_context(type)
          end
          @context_nodes[node_info[0]].delete_at(node_info[1])
        end
        @stickies.pop if @stickies.last == node_info[0]
      end


      def open_context(type, properties = {})
        obj = ASpaceImport::JSONModel(type).new
        @contexts.push(type)
        @batch << obj
        @context_nodes[@node_name] ||= []
        @context_nodes[@node_name][@node_depth] ||= []
        @context_nodes[@node_name][@node_depth] << type
        properties.each do |k,v|
          set obj, k, v
        end

        yield obj if block_given?
      end


      alias_method :make, :open_context


      def close_context(type)
        if @batch.working_area.last.jsonmodel_type != type.to_s
          Log.debug(@batch.working_area.last.inspect)
          raise "Unexpected Object Type in Queue: Expected #{type} got #{@batch.working_area.last.jsonmodel_type}"
        end

        @proxies.discharge_proxy("#{@batch.working_area.last.jsonmodel_type}-#{@contexts.length}", @batch.working_area.last)
        @contexts.pop
        @batch.flush_last
      end


      def inner_xml
        @node.inner_xml.strip
      end


      def append(obj = context_obj, property, value)
        property_type = ASpaceImport::Utils.get_property_type(obj.class.schema['properties'][property.to_s])
        return unless property_type[0].match(/string/) && value.is_a?(String)
        filtered_value = ASpaceImport::Utils.value_filter(property_type[0]).call(value)
        if obj.send(property)
          obj.send(property).send(:<<, property)
        else
          obj.send("#{property}=", filtered_value)
        end
      end


      def set(*args)
        set_property(*args)
      end


      def set_property(obj = context_obj, property, value)
        if obj.nil?
          Log.warn "Tried to set property #{property} on an object that couldn't be found"
          return false
        end

        if property.nil?
          Log.warn("Can't set <#{obj.class.record_type}> <#{property}>: nil value")
          return false
        end

        begin
          property_type = ASpaceImport::Utils.get_property_type(obj.class.schema['properties'][property.to_s])
        rescue NoMethodError
          raise "Having some trouble finding a property <#{property}> on a <#{obj.class.record_type}> object"
        end

        if value.is_a?(ASpaceImport::RecordProxy)
          value.on_discharge(self, :set_property, obj, property)
        else
          if value.nil?
            # Log.debug("Given a nil value for <#{obj.class.record_type}><#{property}>")
          else
            filtered_value = ASpaceImport::Utils.value_filter(property_type[0]).call(value)
            if property_type[0].match /list$/
              obj.send("#{property}").push(filtered_value)
            else
              if obj.send("#{property}")
                Log.warn("Setting a property that has already been set")
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
        @proxies.get_proxy_for("#{record_type}-#{@contexts.length}", record_type)
      end


      def node
        @node
      end


      def ancestor(*types)
        queue_offset = (@context_nodes.has_key?(@node_name) && @context_nodes[@node_name][@node_depth]) ? -2 : -1

        obj = @batch.working_area[0..queue_offset].reverse.find { |o| types.map {|t| t.to_s }.include?(o.class.record_type)}
        block_given? ? yield(obj) : obj
      end


      def att(attribute)
        att_pair = @node.attributes.find {|a| a[0] == attribute}
        if att_pair.nil?
          nil
        else
          att_pair[1]
        end
      end


      def context
        @contexts.last
      end


      def full_context
        @contexts
      end


      def context_obj
        @batch.working_area.last
      end


      def make_sticky(node_name)
        @stickies << node_name
      end
    end
  end
end
