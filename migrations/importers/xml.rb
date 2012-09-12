require 'psych'
require 'nokogiri'

ASpaceImport::Importer.importer :xml do

  def initialize(opts)
    # load in the YAML
    # TODO - die if not given a crosswalk and an input file
    # TODO - require gems at run time? (so it can be listed without giving an error)
    @xw = ASpaceImport::Crosswalk.new(IO.read(opts[:crosswalk]))
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

        @xw.models(:xpath => node.name) do |jo|
          
          record_type = jo.class.record_type
          
          # It would be nice to take care of this in importer.rb
          jo.add_after_save_hook(Proc.new { @goodimports += 1 } )

          # For Debugging
          jo.add_after_save_hook(Proc.new { puts "Saved: #{jo.to_s}" } )


          node.attributes.each do |a|
            
            @xw.properties(:type => record_type, :xpath => "@#{a[0]}") do |p|
              
              jo.send("#{p}=", a[1]) unless jo.send("#{p}")
            end
          end

          # See what ancestor nodes are relationship 
          # endpoints for this node's entity
          @xw.ancestor_relationships(:type => record_type) do |types, property|

            if (ao = @parse_queue.reverse.find {|ao| check_type(ao, types)})
              ao.add_after_save_hook(Proc.new { jo.send("#{property}=", ao.uri) })
              jo.wait_for(ao)
            end
          end      
          
          # We queue once we are finished with an
          # opening tag
          @parse_queue.push(jo)
        end
        
                
        # Does the XML <node> create a property 
        # for an entity in the queue?
        @parse_queue.reverse.each do |jo|
          @xw.get_property(jo.class.record_type, node.name) do |p|
            jo.send("#{p}=", node.inner_xml) unless jo.send("#{p}") #Don't re-set a property
          end
          # if needed: check for ancestor records that need attributes from here
        end
        
            
      # Does the XML </node> match the [-1]
      # object in the parse queue ?
      elsif node.node_type != 1 and @xw.models(
                                          :xpath => node.name, 
                                          :type => @parse_queue[-1].class.record_type
                                          )
                                          
        # TODO - Fill in missing values; add supporting records etc.

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
  
  
  # TODO - get rid of these methods
  def get_entities(xpath)
    @xw.lookup_entities_for(:xpath => xpath)
  end


  def get_property(type, xpath)
    @xw.lookup_property_for(type, xpath)

  end

end

