require 'psych'
require 'nokogiri'

ASpaceImport::Importer.importer :xml do

  def initialize(opts)

    # Validate the file first
    # validate(opts[:input_file]) 

    @reader = Nokogiri::XML::Reader(IO.read(opts[:input_file]))
    @parse_queue = ASpaceImport::ParseQueue.new(opts)

    super

  end


  def self.profile
    "XML pull parser for use with a YAML crosswalk"
  end


  def run
    puts "XMLImporter:run" if $DEBUG
    
    @reader.each do |node|
      
      if node.node_type == 1
        
        puts "Parsing node: #{node.name}" if $DEBUG
        
        node_args = {:xpath => node.name, :depth => node.depth}
        
        target_objects(node_args) do |tob|

          tob.after_save { puts "\nSaved: #{tob.to_s}" } if $DEBUG

          # tob.after_save { |result| puts "RESULTS #{result.inspect}" }
          tob.after_save { |result| log_save_result(result) }
          
          tob.receivers.for(:xpath => "self") do |r|
            r.receive(node.inner_xml)
          end

          node.attributes.each do |a|
            
            tob.receivers.for(:xpath => "@#{a[0]}") do |r|
              r.receive(a[1])
            end                         
          end

          # Links from current object to ojects in the queue

          @parse_queue.reverse.each do |qdob|
            tob.receivers.for(:depth => qdob.depth, 
                              :record_type => qdob.class.record_type) do |r|

              r.receive(qdob.uri)
              # qdob.after_save { r.receive(qdob.uri) }
              # tob.wait_for(qdob)
            end
          end
          
          # Links from objects in the queue to current object

          @parse_queue.reverse.each do |qdob|

            qdob.receivers.for(node_args) do |r|
              r.receive(tob.uri)
              # tob.after_save { r.receive(tob.uri) }
              # qdob.wait_for(tob)
            end

          end        
          
          # Add current object to parsing queue
          
          @parse_queue.push(tob)
        end     
                
        # Does the XML <node> create a property 
        # for an entity in the queue?
           
        @parse_queue.reverse.each do |qdob|
          
          qdob.receivers.for(node_args) do |r|
            puts "Node args: #{node_args.inspect} -- Receiver: #{r.to_s}" if $DEBUG
            r.receive(node.inner_xml)
          end
              
          # TODO (if needed): objects in queue that need attributes of
          # current node
        end
            
      # Remove objects from the queue once their nodes close

      elsif node.node_type != 1 and target_objects(:xpath => node.name, :depth => node.depth)

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

