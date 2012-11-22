require 'psych'
require 'nokogiri'

ASpaceImport::Importer.importer :xml do

  def initialize(opts)

    # Validate the file first
    # validate(opts[:input_file]) 

    @reader = Nokogiri::XML::Reader(IO.read(opts[:input_file]))
    @parse_queue = ASpaceImport::ParseQueue.new(opts)
    
    # In DEBUG mode, generate a CSV audit trail
    set_up_tracer if $DEBUG   
      
    super

  end


  def self.profile
    "XML pull parser for use with a YAML crosswalk"
  end


  def run
    
    @reader.each do |node|
     
      node_args = {:xpath => node.name, :depth => node.depth, :node_type => node.node_type}
      
      node.start_trace if $DEBUG

      if node.node_type == 1
        if (json = self.class.object_for_node(node))

          json.receivers.for(:xpath => "self") do |r|
            r.receive(node.inner_xml)
          end
          
          json.receivers.for(:xpath => "self::name") do |r|
            r.receive(node.name)
          end
          
          node.attributes.each do |a|        
            json.receivers.for(:xpath => "@#{a[0]}") do |r|
              r.receive(a[1])
            end                         
          end
          
          @parse_queue.push(json)
        else
          @parse_queue.receivers.for(node_args) do |r|
            r.receive(node.inner_xml)
          end
        end
      # If a closing tag matches a node
      elsif (json = self.class.object_for_node(node, @parse_queue))
        json.set_default_properties
    
        # Temporary hacks and whatnot:                                          
        # Fill in missing values; add supporting records etc.
        # For instance:
      
        if ['subject'].include?(json.class.record_type)
        
          @vocab_uri ||= "/vocabularies/#{@vocab_id}"
    
          json.vocabulary = @vocab_uri
          json.terms.each {|t| t['vocabulary'] = @vocab_uri}
        end
      
        @parse_queue.pop
      end

    end
    
    log_save_result(@parse_queue.save)
    puts "TRACER OUT"
    $tracer.out(@uri_map)
  end  


  # Very rough XSD validation (Not working yet)
  
  def validate(input_file)
    
    open(input_file).read().match(/xsi:schemaLocation="[^"]*(http[^"]*)"/)
    
    require 'net/http'
    
    uri = URI($1)
    xsd_file = Net::HTTP.get(uri)
    
    xsd = Nokogiri::XML::Schema(xsd_file)
    doc = Nokogiri::XML(File.read(input_file))

    xsd.validate(doc).each do |error|
      # @import_log << "Invalid Source: " + error.message
    end
  
  end
  
  protected
  
  def set_up_tracer
    require 'tmpdir'
    $tracer = Tracer.new
    
    ASpaceImport::Crosswalk::ClassMethods.module_eval do
      alias :object_for_node_original :object_for_node
    
      def object_for_node(node, *q)
      
        if (json = object_for_node_original(node, *q))
          $tracer.trace(:aspace_data, json, nil) if node.node_type == 1

          json
        else
          false
        end
      end
    end

    
    Nokogiri::XML::Reader.class_eval do
      alias_method :inner_xml_original, :inner_xml

      def start_trace
        $tracer.set_node(self)
      end

      def inner_xml
        $tracer.trace(:inner_xml, inner_xml_original)
        inner_xml_original
      end
          
    end
    
    ASpaceImport::Crosswalk::PropertyReceiver.class_eval do
      alias_method :receive_original, :receive
      
      def receive(val = nil)
        if receive_original(val)
          if @json.send("#{@prop}") and @type == 'string'
            received_val = @json.send("#{@prop}")
          elsif @json.send("#{@prop}") and @type == 'array'
            received_val = @json.send("#{@prop}").last
          end

          $tracer.trace(:aspace_data, json, prop, received_val)
        end
      end
    end
  end

end

class Tracer
  attr_accessor :registry
  
  def initialize(tfile = File.new("#{Dir.tmpdir}/ead-trace.tsv", "w"))
    @file = tfile
    @depth, @index, @xpath, @registry = 0, 0, "/", []
  end
  
  def set_node(node)
    @index += 1 unless @index == 0 and @registry.length == 0
    @registry[@index] = {
                          :node_type => node.node_type, 
                          :node_value => node.value? ? node.value.sub(/[\s\n]*$/, '') : nil,
                          :xpath => set_xpath(node),
                          :aspace_data => [],
                          :inner_xml => []
                        }
  end

  
  def trace(key, *j, val)
    json, prop = j

    val = sanitize(val)

    if json and json.class.method_defined? :uri
      ref = prop ? "#{json.uri}\##{prop}" : "#{json.uri}"
    elsif json
      ref = prop ? "#{json.class.to_s}\##{prop}" : "#{json.class.to_s}"
    end
    raise "STOP" if val.class.method_defined? :jsonmodel_type and val.jsonmodel_type == 'archival_object'

    if key == :aspace_data
      @registry[@index][key] << [ref, val]
    else
      @registry[@index][key] << val
    end
  end
  
  def sanitize(val)

    return if val.nil? 
    return val if val.is_a?(Hash)

    if val.class.method_defined? :uri
      val = val.uri
    end


    val.gsub!(/^\s*/, '')
    val.gsub!(/\s*$/, '')
    val.gsub!(/[\t\n\r]/, '')

    val
  end
  
  def out(map = {})
    @file.write(%w(00000 NODE.TYPE XPATH NODE.XML NODE.TEXT ASPACE.REF ASPACE.VAL).join("\t").concat("\n"))
    # @file.write("'ROW'\t""'NODE_TYPE'\t'XPATH'\t'NODE.INNER_XML'\t'NODE.VALUE'\t'ASPACE DATA'\n")
    @registry.each_with_index do |l, i|

      [1, l[:aspace_data].length].max.times do |j|
        
        if l[:aspace_data][j].is_a?(Array)
          aspace_data = "#{l[:aspace_data][j][0]}\t#{l[:aspace_data][j][1]}"
        else
          aspace_data = "\t"
        end
        
        if j == 0
          line = "#{'%05d' % i}-#{j}\t#{l[:node_type]}\t#{l[:xpath]}\t#{l[:inner_xml][j]}\t#{l[:node_value]}\t#{aspace_data}\n"
        else
          line = "#{'%05d' % i}-#{j}\t\t\t#{l[:inner_xml][j]}\t\t#{aspace_data}\n"
        end
        map.each do |posted_uri, actual_uri|
          line.gsub!(posted_uri, actual_uri)
        end
      
        @file.write(line)
      end
    end
  end 
  
   
  def set_xpath(node)
    if @depth < node.depth
      @xpath.concat("/#{node.name}")
    elsif @depth == node.depth
      @xpath.sub!(/\/[#a-z0-9]*$/, "/#{node.name}")
    elsif @depth > node.depth
      @xpath.sub!(/\/[#a-z0-9]*\/[#a-z0-9]*$/, "/#{node.name}")
    else
      raise "Doh!"
    end
    @depth = node.depth
    @xpath.clone
  end
end   

