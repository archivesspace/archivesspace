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
    @reader.each do |node|
      if node.node_type == 1
        
        target_objects(:xpath => node.name, :depth => node.depth) do |tob|

          # For Debugging / Testing
          tob.after_save { puts "\nSaved: #{tob.to_s}" }
          
          # Set any properties that take 'self'
          tob.set_properties(:xpath => "self",
                            :value => node.inner_xml)

          node.attributes.each do |a|
            
            tob.set_properties(:xpath => "@#{a[0]}",
                              :value => a[1])
          end

          # Does this object need something in the parse
          # queue to set one of it's (the current object) 
          # properties?
          
          tob.ancestor_relationships do |types, property|

            if (qob = @parse_queue.reverse.find {|qob| check_type(qob, types)})
              qob.after_save { tob.send("#{property}=", qob.uri) }
              tob.wait_for(qob)
            end
          end
          
          # Does this object satisfy a property of
          # somethign in the queue?

          @parse_queue.reverse.each do |qob|

            xpath = node.name
            if node.depth - qob.depth == 1
              xpath.insert(0, 'child::')
            elsif node.depth - qob.depth > 1
              xpath.insert(0, 'descendant::')
            else
              next 
            end
            
            # This needs revision.
            # Won't work if the child object ends 
            # up waiting on something else            
            tob.after_save { qob.set_properties(:xpath => xpath,
                                              :value => tob.uri) }

          end        
          
          # Store the object in the parse queue
          # until the closing tag gets read
          
          @parse_queue.push(tob)
        end     
                
        # Does the XML <node> create a property 
        # for an entity in the queue?
        
        @parse_queue.reverse.each do |qob|

          xpath = node.name
          if node.depth - qob.depth == 1
            xpath.insert(0, 'child::')
          elsif node.depth - qob.depth > 1
            xpath.insert(0, 'descendant::')
          else
            next 
          end
     
          qob.set_properties(:xpath => xpath,
                            :value => node.inner_xml )

          
        # TODO (if needed): check for ancestor records 
        # that need attributes from the present node
        end
        
            
      # Does the XML </node> match the [-1]
      # object in the parse queue ?
      elsif node.node_type != 1 and target_objects(
                                          :xpath => node.name, 
                                          :type => @parse_queue[-1].class.record_type
                                          )
                                          
        # Fill in missing values; add supporting records etc.
        # Hardcoded property sets should be abstracted or the
        # data model should be re-examined
        
        # For instance:
        if ['subject'].include?(@parse_queue[-1].class.record_type)
          
          @vocab_uri ||= "/vocabularies/#{@vocab_id}"

          @parse_queue[-1].vocabulary = @vocab_uri
          if @parse_queue[-1].terms.is_a?(Array)
            @parse_queue[-1].terms.each {|t| t['vocabulary'] = @vocab_uri}
          end
        end


        # Save or send to waiting area
        @parse_queue.pop    
        
      end
    end
  end
  
  
  def check_type(ob, types)
    if ob and types.include?(ob.class.record_type)
      ob
    else
      nil
    end
  end
  
  

end

