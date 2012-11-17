require 'psych'
require 'nokogiri'

ASpaceImport::Importer.importer :xml do

  def initialize(opts)

    # Validate the file first
    # validate(opts[:input_file]) 

    @reader = Nokogiri::XML::Reader(IO.read(opts[:input_file]))
    @parse_queue = ASpaceImport::ParseQueue.new(opts)
    
    
    # TO DO NEXT - Commit working version and try to move the tracer object 
    # to sit in the importer. Add aliases to the receiver. node.start_trace
    # will change the current node in the Tracer
    
    if $DEBUG
      require 'tmpdir'
      @tfile = File.new("#{Dir.tmpdir}/ead-trace.csv", "w")
      @tfile_buffer = ["'NODE_TYPE', 'XPATH', 'NODE.INNER_XML', 'NODE.VALUE', 'ASPACE DATA'\n"]
  
      
      Nokogiri::XML::Reader.class_eval do
        alias_method :inner_xml_original, :inner_xml
        attr_reader :tracer
        
        def start_trace
          @tracer = Tracer.new(self)
        end

        def inner_xml
          self.tracer.inner_xml = inner_xml_original
          self.tracer.inner_xml
        end
            
      end 
    end
      
    super

  end


  def self.profile
    "XML pull parser for use with a YAML crosswalk"
  end


  def run
    puts "XMLImporter:run" if $DEBUG
    
    @reader.each do |node|
     
      node_args = {:xpath => node.name, :depth => node.depth}
      
      if $DEBUG
        node.start_trace
        node_args.merge!(:tracer => node.tracer)
      end

      if node.node_type == 1
        
        handle_node(node_args) do |obj|
          
          node.tracer.record_properties.push(obj.uri) if $DEBUG
          
          obj.receivers.for(:xpath => "self") do |r|
            r.receive(node.inner_xml)
            node.tracer.record_properties.push("#{r.json.uri}\##{r.prop}") if $DEBUG
          end

          node.attributes.each do |a|
            
            obj.receivers.for(:xpath => "@#{a[0]}") do |r|
              r.receive(a[1])
              node.tracer.record_properties.push("#{r.json.uri}\##{r.prop} << @#{a[0]}") if $DEBUG
            end                         
          end
          
          # Add current object to parsing queue          
          @parse_queue.push(obj)
        end     
                
        # Does the XML <node> create a property 
        # for an entity in the queue?
                     
        @parse_queue.receivers(node_args) do |r|

          r.receive(node.inner_xml)
          node.tracer.record_properties.push("#{r.json.uri}\##{r.prop}") if $DEBUG 
        end
              
          # TODO (if needed): objects in queue that need attributes of
          # current node

      # Remove objects from the queue once their nodes close

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

      # @tfile.write(node.tracer.trace) if $DEBUG
      @tfile_buffer << node.tracer.trace if $DEBUG
    end
    
    log_save_result(@parse_queue.save)

    # puts import_log[0].inspect if $DEBUG
    # update the CSV file with correct links
    if $DEBUG
      @uri_map.each do |posted_uri, actual_uri|
        @tfile_buffer.map! {|l| l.gsub(posted_uri, actual_uri)}
      end
      @tfile_buffer.each do |line|
        @tfile.write(line)
      end
    end
  end  


  # Very rough XSD validation
  
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
  

end

class Tracer
  
  @@xp = "/"
  @@d = 0
  
  attr_accessor :text_used
  attr_accessor :xpath
  attr_accessor :record_uri
  attr_accessor :inner_xml
  attr_accessor :record_properties
  
  def initialize(node)
    @node = node
    set_xpath
    @@d = @node.depth
    @record_properties = []
  end
  
  def trace
    %Q^#{@node.name} (#{@node.node_type}), #{@xpath}, "#{@inner_xml}", "#{@node.value}", "#{record_properties.join("\n")}"\n^
  end
  
  def set_xpath
    if @@d < @node.depth
      @@xp.concat("/#{@node.name}")
    elsif @@d == @node.depth
      @@xp.sub!(/\/[#a-z0-9]*$/, "/#{@node.name}")
    elsif @@d > @node.depth
      @@xp.sub!(/\/[#a-z0-9]*\/[#a-z0-9]*$/, "/#{@node.name}")
    else
      raise "What"
    end
    @xpath = @@xp.clone
  end 
end
  

# class Tracer
#   def initialize
#     @tfile = File.new("#{Dir.tmpdir}/ead-trace.xml", "w")
#     @xpath = ''
#     @depth = 0
#     @tfile.write("'XPATH', 'SOURCE VALUE', 'ASPACE RESULT'\n")
#     @tline = {:xpath => nil, :source_val => nil, :uri => nil}
#     @node_open = false
#   end
#   
#   def trace_node(node)
# 
#     puts "Node #{node.name}: Type #{node.node_type}"
# 
#     if node.node_type != 1 and node.node_type != 15
#       puts "Closing"
#       @node_open = false
#       puts @tline.inspect
#       @tfile.write(@tline.map { |k,v| v }.join(',') << "\n")
#       @tfile.flush
#     elsif node.node_type == 3 or node.node_type == 14
#       @tline[:source_val] = node.value
#     else
#       @node_open = true    
#       if node.depth.to_i == @depth + 1
#         @xpath << "/#{node.name}"
#       elsif node.depth.to_i == @depth
#         @xpath.sub!(/\/[a-z0-9]*$/, '/')
#         @xpath << node.name
#       elsif node.depth.to_i == @depth - 1
#         @xpath.sub!(/\/[a-z0-9]*\/[a-z0-9]*$/, '/')
#         @xpath << node.name
#       else
#         raise "Unexpected difference between node depths #{@depth} -- #{node.depth} -- #{node.name}"
#       end
#     
#       @depth = node.depth
# 
#       @tline[:xpath] = @xpath
#       @tline[:source_val] = node.value if node.value?
#       @tline[:uri] = "/aspace"
#     end
#       
#     # @tfile.write("#{@xpath}, #{val}, TBD\n")
#     
#     # node.depth.to_i.times { @tfile.write("\t") }      
#     # @tfile.write("<#{node.node_type != 1 ? '/' : ''}#{node.name}>\n")
# 
#   end
#   
#   def report
#     puts "TRACER FILE: #{@tfile.path}\n"
#   end
# end