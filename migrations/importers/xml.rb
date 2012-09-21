require 'psych'
require 'nokogiri'

ASpaceImport::Importer.importer :xml do

  def initialize(opts)
    # load in the YAML
    # TODO - die if not given a crosswalk and an input file
    # TODO - require gems at run time? (so it can be listed without giving an error)
    @xw = ASpaceImport::Crosswalk.new(opts)
    @reader = Nokogiri::XML::Reader(IO.read(opts[:input_file]))
    # TODO - create a separate module for the parse queue
    #     since it doesn't have much to do with JSONModel (?)
    @parse_queue = ASpaceImport::ParseQueue.new(opts)
    super
  end


  def self.profile
    "XML pull parser for use with a YAML crosswalk"
  end


  def run
    @reader.each do |node|
      if node.node_type == 1
        
        @xw.models(:xpath => node.name, :depth => node.depth) do |jo|
          
          record_type = jo.class.record_type
          
          eval("def jo.depth; #{node.depth}; end")
          
          jo.add_after_save_hook(Proc.new { @goodimports += 1 } )

          # For Debugging / Testing
          jo.add_after_save_hook(Proc.new { puts "\nSaved: #{jo.to_s}" } )
          
          # Set any properties that take 'self'
          @xw.set_properties( :object => jo,
                              :xpath => "self",
                              :value => node.inner_xml
                            )

  
          node.attributes.each do |a|
            

            @xw.set_properties( :object => jo,
                                :xpath => "@#{a[0]}",
                                :value => a[1] )

          end

          # Does this object need something in the parse
          # queue to set one of it's (the current object) 
          # properties?
          
          @xw.ancestor_relationships(:type => record_type) do |record_types, property|

            if (ao = @parse_queue.reverse.find {|ao| check_type(ao, record_types)})
              ao.add_after_save_hook(Proc.new { jo.send("#{property}=", ao.uri) })
              jo.wait_for(ao)
            end
          end
          
          # Does this object satisfy a property of
          # somethign in the queue?

          @parse_queue.reverse.each do |ao|

            xpath = node.name
            if node.depth - ao.depth == 1
              xpath.insert(0, 'child::')
            elsif node.depth - ao.depth > 1
              xpath.insert(0, 'descendant::')
            else
              next 
            end
            
            # This needs revision.
            # Won't work if the child object ends 
            # up waiting on something else            
            jo.add_after_save_hook(Proc.new {
                                            @xw.set_properties( :object => ao,
                                                                :xpath => xpath,
                                                                :value => jo.uri)
                                            })

          end
          
          
          
          # We queue once we are finished with an
          # opening tag
          
          @parse_queue.push(jo)
        end
        
                
        # Does the XML <node> create a property 
        # for an entity in the queue?
        
        
        @parse_queue.reverse.each do |jo|

          xpath = node.name
          if node.depth - jo.depth == 1
            xpath.insert(0, 'child::')
          elsif node.depth - jo.depth > 1
            xpath.insert(0, 'descendant::')
          else
            next 
          end
     
          @xw.set_properties( :object => jo,
                              :xpath => xpath,
                              :value => node.inner_xml )


          
          
        # TODO (if needed): check for ancestor records 
        # that need attributes from the present node
        end
        
            
      # Does the XML </node> match the [-1]
      # object in the parse queue ?
      elsif node.node_type != 1 and @xw.models(
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
  
  
  def check_type(jo, types)
    if jo and types.include?(jo.class.record_type)
      jo
    else
      nil
    end
  end
  
  

end

