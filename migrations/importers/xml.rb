require 'psych'
require 'nokogiri'

ASpaceImport::Importer.importer :xml do

  def initialize(opts)

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
          
          tob.receivers.for(:xpath => "self") do |r|
            r.receive(node.inner_xml)
          end

          node.attributes.each do |a|
            
            tob.receivers.for(:xpath => "@#{a[0]}") do |r|
              r.receive(a[1])
            end                         
          end

          # Outgoing Links to Ancestors
          # Does this object need something in the parse
          # queue to set one of it's (the current object) 
          # properties?

          @parse_queue.reverse.each do |qdob|
            tob.receivers.for(:depth => qdob.depth, 
                              :record_type => qdob.class.record_type) do |r|

              qdob.after_save { r.receive(qdob.uri) }
              tob.wait_for(qdob)
            end
          end
          
          # Incoming Links from Ancestors
          # Does this object satisfy a property of
          # somethign in the queue?

          @parse_queue.reverse.each do |qdob|

            qdob.receivers.for(node_args) do |r|
              tob.after_save { r.receive(tob.uri) }
              qdob.wait_for(tob)
            end

          end        
          
          # Store the object in the parse queue
          # until the closing tag gets read
          
          @parse_queue.push(tob)
        end     
                
        # Does the XML <node> create a property 
        # for an entity in the queue?
           
        @parse_queue.reverse.each do |qdob|
          
          qdob.receivers.for(node_args) do |r|
            puts "Node args: #{node_args.inspect} -- Receiver: #{r.to_s}" if $DEBUG
            r.receive(node.inner_xml)
          end
              
        # TODO (if needed): check for ancestor records 
        # that need attributes from the present node
        end

            
      # Does the XML </node> match the [-1]
      # object in the parse queue ?

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
  

end

