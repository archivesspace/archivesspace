require 'psych'
require 'nokogiri'

ASpaceImport::Importer.importer :xml do

  def initialize(opts)

    # Validate the file first
    # validate(opts[:input_file]) 
    
    hack_input_file_for_dumb_nokogiri_exceptions(opts)

    @reader = Nokogiri::XML::Reader(IO.read(opts[:input_file]))
    @parse_queue = ASpaceImport::ParseQueue.new(opts)
    
    @xpath, @depth = "/", 0
    
    # In DEBUG mode, generate a TSV audit trail
    set_up_tracer if $DEBUG   
      
    super

  end


  def self.profile
    "XML pull parser for use with a YAML crosswalk"
  end


  def run
    
    puts Nokogiri::VERSION if $DEBUG
    
    @reader.each do |node|

      node_args = [xpath(node), node.depth, node.node_type]
            
      node.start_trace(*node_args) if $DEBUG

      if node.node_type == 1
        if (json = self.class.object_for_node(*node_args))

          json.receivers.for_node("self") do |r|
            r.receive(node.inner_xml)
          end
          
          json.receivers.for_node("self::name") do |r|
            r.receive(node.name)
          end
          
          node.attributes.each do |a|        
            json.receivers.for_node("@#{a[0]}") do |r|
              r.receive(a[1])
            end                         
          end
          
          @parse_queue.push(json)
        else
          @parse_queue.receivers.for_node(*node_args) do |r|
            r.receive(node.inner_xml)
          end
        end

      elsif node.node_type == 3
        @parse_queue.receivers.for_node(*node_args) do |r|
          r.receive(node.value.sub(/[\s\n]*$/, ''))
        end
      
      # If a closing tag matches a node
      elsif (json = self.class.object_for_node(*node_args, @parse_queue))
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
    $tracer.out(@uri_map) if $DEBUG
  end  


  # Very rough XSD validation (Not working yet)
  
  def validate(input_file)
    
    # open(input_file).read().match(/xsi:schemaLocation="[^"]*(http[^"]*)"/)
    # 
    # require 'net/http'
    # 
    # uri = URI($1)
    # xsd_file = Net::HTTP.get(uri)
    # 
    # xsd = Nokogiri::XML::Schema(xsd_file)
    # doc = Nokogiri::XML(File.read(input_file))
    # 
    # xsd.validate(doc).each do |error|
    # end
  
  end
  
  protected
  
  def xpath(node)
    
    name = node.name.gsub(/#text/, "text()")


    if @depth < node.depth
      @xpath.concat("/#{name}")
    elsif @depth == node.depth
      @xpath.sub!(/\/[#()a-z0-9]*$/, "/#{name}")
    elsif @depth > node.depth
      @xpath.sub!(/\/[#()a-z0-9]*\/[#()a-z0-9]*$/, "/#{name}")
    else
      raise "Can't parse node depth to create XPATH"
    end
    

    @depth = node.depth
    @xpath.clone
  end
  
  def set_up_tracer
    require 'tmpdir'
    $tracer = Tracer.new
    
    ASpaceImport::Crosswalk::module_eval do
      alias :object_for_node_original :object_for_node
    
      def object_for_node(*parseargs)
      
        if (json = object_for_node_original(*parseargs))
          nname, ndepth, ntype = *parseargs
          $tracer.trace(:aspace_data, json, nil) if ntype == 1
    
          json
        else
          false
        end
      end
    end

    
    Nokogiri::XML::Reader.class_eval do
      alias_method :inner_xml_original, :inner_xml

      def start_trace(*parseargs)
        $tracer.set_node(self, parseargs[0])
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
          set_val = @object.send("#{self.class.property}") 
          if set_val.is_a? String
            received_val = @object.send("#{self.class.property}")
          elsif set_val and set_val.is_a? Array
            received_val = @object.send("#{self.class.property}").last
          end

          $tracer.trace(:aspace_data, @object, self.class.property, received_val)
        end
      end
    end
  end

  protected
  
  def hack_input_file_for_dumb_nokogiri_exceptions(opts)
    
    # Workaround for Nokogiri bug:
    # https://github.com/sparklemotion/nokogiri/pull/805
    
    new_file = File.new(opts[:input_file].gsub(/\.xml/, '_no_xlink.xml'), "w")
    
    File.open opts[:input_file], 'r' do |f|
      f.each_line do |line|
        new_file.puts line.gsub(/\sxlink:href=\".*?\"/, "")
      end
    end
    
    new_file.close
    
    opts[:input_file] = new_file.path
  end

end

class Tracer
  attr_accessor :registry
  
  def initialize(tfile = File.new("#{Dir.tmpdir}/ead-trace.tsv", "w"))
    @file = tfile
    @index, @registry = 0, []
  end
  
  def set_node(node, xpath)
    @index += 1 unless @index == 0 and @registry.length == 0
    @registry[@index] = {
                          :node_type => node.node_type, 
                          :node_value => node.value? ? node.value.sub(/[\s\n]*$/, '') : nil,
                          :xpath => xpath,
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
end   

