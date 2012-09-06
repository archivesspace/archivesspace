require 'psych'
require 'nokogiri'

ASpaceImport::Importer.importer :xml do

  def initialize(opts)
    # load in the YAML
    # TODO - die if not given a crosswalk and an input file
    # TODO - require gems at run time? (so it can be listed without giving an error)
    @xwalk = ASpaceImport::Crosswalk.new(IO.read(opts[:crosswalk]))
    @reader = Nokogiri::XML::Reader(IO.read(opts[:input_file]))
    # TODO - create a separate module for the parse queue
    #     since it doesn't have much to do with JSONModel (?)
    @parse_queue = JSONModel::Client.queue(opts)
    super
  end


  def self.profile
    "XML pull parser for use with a YAML crosswalk"
  end


  def run
    @reader.each do |node|
      if node.node_type == 1
        if (entity_type = get_entity(node.name))
          # TODO - error handling in case there isn't a schema to match
          jo = JSONModel(entity_type).new                  
          # Go through the attributes and look for properties
          node.attributes.each do |a|
            if (property = get_property(entity_type, "@#{a[0]}"))              
              jo.send("#{property}=", a[1]) if jo.respond_to?(property)
            end
          end
          # See if the parent node is referenced by a property
          @xwalk.properties(entity_type) {|prop, xpaths|
            xpaths.each do |xp|
              if xp.match(/^parent::([a-z]*)$/)
                parent_type = get_entity($1)
                # if the current node calls for something on the parent axis, 
                # that should be the last item in the queue
                if (po = validate(@parse_queue[-1], parent_type))
                  po.add_after_save_hook(Proc.new { jo.send("#{prop}=", po.uri) })
                  jo.wait_for(po)
                end
              end  
            end
          }
          # We queue once we are finished with an opening tag
          jo.enqueue
        # Does the XML <node> create a property for the last entity in the queue?
        elsif (jo = @parse_queue[-1])
          if (property = get_property(jo.class.record_type, node.name))
            @parse_queue[-1].send("#{property}=", node.inner_xml)
          end
        end
      # Does the XML </node> match an entity?
      elsif node.node_type != 1 and (entity_type = get_entity(node.name))
        @parse_queue.pop if validate(@parse_queue[-1], entity_type) #Save or send to waiting area
      end
    end
  end
  
  def validate(jo, et)
    if jo and jo.class.record_type
      jo
    else
      nil
    end
  end
  
  # TODO - move these methods to the Crosswalk class.
  def get_entity(xpath)
    @xwalk.lookup_entity_for(xpath)
  end


  def get_property(type, xpath)
    @xwalk.lookup_property_for(type, xpath)

  end

end

