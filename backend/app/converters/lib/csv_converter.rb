require 'csv'
require_relative 'utils'
require_relative 'record_proxy'

module ASpaceImport
  module CSVConvert

    module ClassMethods
      def configuration
        @configuration ||= self.configure
      end


      def configure_cell_handlers(row)
        headers = row.map {|s| s ||= ""; s.strip}.reject{|s| s.empty? }
        c = configuration
        bad_headers = []
        headers.each {|h| bad_headers << h unless h.match /^[a-z]*_[a-z0-9_]*$/ }

        if !bad_headers.empty?
          raise CSVSyntaxException.new(:bad_headers, bad_headers)
        end

        headers.each {|h| bad_headers << h unless c.has_key?(h)}

        if !bad_headers.empty?
          # raise CSVSyntaxException.new(:unconfigured_headers, bad_headers)
        end

        cell_handlers = headers.map {|h| c.has_key?(h) ? CellHandler.new(*[*c[h], h].reverse) : nil }

        [cell_handlers, bad_headers]
      end
    end


    def self.included(base)
      base.extend(ClassMethods)
    end


    def configuration
      self.class.configuration
    end


    def run

      @cell_handlers = []
      @proxies = ASpaceImport::RecordProxyMgr.new

      CSV.foreach(@input_file, { encoding: 'BOM|UTF-8' }) do |row|
        # Entirely blank rows can be safely ignored
        next if row.all? {|cell| cell.to_s.strip.empty? }

        if @cell_handlers.empty?
          @cell_handlers, bad_headers = self.class.configure_cell_handlers(row)
          unless bad_headers.empty?
            Log.warn("Data source has headers that aren't defined: #{bad_headers.join(', ')}")
          end
        else
          parse_row(row)
        end
      end

      @proxies.undischarged.each do |prox|
        Log.warn("Undischarged: #{prox.to_s}")
      end
    end


    def parse_row(row)
      row.each_with_index { |cell, i| parse_cell(@cell_handlers[i], cell) }

      # swap out proxy objects for real JSONModel objects
      @batch.working_area.map! {|proxy| proxy.spawn }.compact!

      # run linking jobs and set defaults
      @batch.working_area.each { |obj| @proxies.discharge_proxy(obj.key, obj) }

      # empty the working area of the cache
      @batch.flush
    end


    def parse_cell(handler, cell_contents)

      return nil unless handler

      val = handler.extract_value(cell_contents)

      return nil unless val

      get_queued_or_new(handler.target_key) do |prox|
        property = handler.target_path
        prox.set(property, val)
      end
    end


    def get_queued_or_new(key)
      if (prox = @batch.working_area.find {|j| j.key == key })
        yield  prox
      elsif (prox = get_new(key))
        yield prox
        @batch << prox
      end
    end


    def get_new(key)

      conf = configuration[key.to_sym] || {}

      type = conf[:record_type] ? conf[:record_type] : key

      proxy = @proxies.get_proxy_for(key, type)

      if conf[:on_create]
        proxy.on_spawn(conf[:on_create])
      end

      # Set defaults when done getting data
      if conf[:defaults]
        conf[:defaults].each do |key, val|
          proxy.on_discharge(self, :set_default, key, val)
        end
      end

      # Set links before batching the record
      if conf[:on_row_complete]
        proxy.on_discharge(conf[:on_row_complete], :call, @batch.working_area)
      end

      proxy
    end


    def set_default(property, val, obj)
      if obj.send("#{property}").nil?
        obj.send("#{property}=", val)
      end
    end


    class CellHandler
      attr_reader :name
      attr_reader :target_key
      attr_reader :target_path

      def initialize(name, data_path, val_filter = nil)
        @name = name
        @target_key, @target_path = data_path.split(".")
        @val_filter = val_filter
      end


      def extract_value(cell_contents)
        return nil if cell_contents.nil? || cell_contents == 'NULL'
        @val_filter ? @val_filter.call(cell_contents) : cell_contents
      end
    end


    class CSVSyntaxException < StandardError

      def initialize(type, element)
        @type = type
        @element = element
      end

      def to_s
        "#<:CSVSyntaxException: #{@type} => #{@element.inspect}"
      end
    end

  end
end
