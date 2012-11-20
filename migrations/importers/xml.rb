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
        
        handle_node(node_args) do |obj|
          
          obj.receivers.for(:xpath => "self") do |r|
            r.receive(node.inner_xml)
          end

          node.attributes.each do |a|
            
            obj.receivers.for(:xpath => "@#{a[0]}") do |r|
              r.receive(a[1])
            end                         
          end
          
          @parse_queue.push(obj)
        end     
                
        # Apply the node to the parse queue
                     
        @parse_queue.receivers(node_args) do |r|
          r.receive(node.inner_xml)
        end

      elsif node.node_type != 1 and handle_node(node_args)

        # Set defaults for missing values
        
        @parse_queue[-1].set_default_properties

        # Temporary hacks and whatnot:                                          
        # Fill in missing values; add supporting records etc.
        # For instance:
        
        if ['subject'].include?(@parse_queue[-1].class.record_type)
          
          @vocab_uri ||= "/vocabularies/#{@vocab_id}"

          @parse_queue[-1].vocabulary = @vocab_uri
          if @parse_queue[-1].terms.is_a?(Array)
            @parse_queue[-1].terms.each {|t| t['vocabulary'] = @vocab_uri}
          end
        end

        # Save or send to waiting area
        puts "Finished parsing #{node.name}" if $DEBUG

        @parse_queue.pop          
      end

    end
    
    log_save_result(@parse_queue.save)
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
    
    self.instance_eval do
      alias :handle_node_original :handle_node
    
      def handle_node(opts)
      
        handle_node_original(opts) do |result|
          return result unless result.class.method_defined? :jsonmodel_type
          if opts[:node_type] != 15
            $tracer.trace(:aspace_data, result.uri)
          end
          yield result if block_given?

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
        receive_original(val)
        if @json.send("#{@prop}") and @type == 'string'
          val = @json.send("#{@prop}")
          $tracer.trace(:aspace_data, "#{json.uri}\##{prop} << #{val}")
        elsif @json.send("#{@prop}") and @type == 'array'
          val = @json.send("#{@prop}").last
          $tracer.trace(:aspace_data, "#{json.uri}\##{prop} << #{val}")
        elsif @type.match(/^JSONModel/) 
          $tracer.trace(:aspace_data, "#{json.uri}\##{prop} << #{val}")
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

  
  def trace(key, val)
    # @registry[@index][key] ||= []
    @registry[@index][key] << val
  end
  
  def out(map = {})
    @file.write("'ROW'\t""'NODE_TYPE'\t'XPATH'\t'NODE.INNER_XML'\t'NODE.VALUE'\t'ASPACE DATA'\n")
    @registry.each_with_index do |l, i|

      [1, l[:aspace_data].length].max.times do |j|
        if j == 0
          line = "#{i}\t#{l[:node_type]}\t#{l[:xpath]}\t#{l[:inner_xml][j]}\t#{l[:node_value]}\t#{l[:aspace_data][j]}\n"
        else
          line = "#{i}\t\t\t#{l[:inner_xml][j]}\t\t#{l[:aspace_data][j]}\n"
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

