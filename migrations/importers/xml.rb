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
      spawns_a_record = false #(not really using this yet - may not need it)
      if node.node_type == 1
        @xw.set_schema(node.name) do |s|
          jo = JSONModel(s).new
          node.attributes.each do |a|
            @xw.get_property(s, "@#{a[0]}") do |p|
              jo.send("#{p}=", a[1]) unless jo.send("#{p}")
            end
          end
          # See what ancestor nodes are relationship endpoints for this node's entity
          @xw.ancestor_relationships do |ancestor_schema, r|
            if (ao = @parse_queue.reverse.find {|ao| validate(ao, ancestor_schema)})
              ao.add_after_save_hook(Proc.new { jo.send("#{r}=", ao.uri) })
              jo.wait_for(ao)
            end
          end      
          
          # We queue once we are finished with an opening tag
          @parse_queue.push(jo)
        end #end processing the node into a schema
        # Does the XML <node> create a property for an entity in the queue?
        @parse_queue.reverse.each do |jo|
          @xw.get_property(jo.class.record_type, node.name) do |p|
            jo.send("#{p}=", node.inner_xml) unless jo.send("#{p}") #Don't re-set a property
          end
          # if needed: check for ancestor records that need attributes from here
        end       

      # Does the XML </node> match an entity?
      elsif node.node_type != 1 and (entity_type = get_entity(node.name))
        @parse_queue.pop if validate(@parse_queue[-1], entity_type) #Save or send to waiting area
      end
    end
  end
  
  def validate(jo, et)
    if jo and jo.class.record_type == et
      jo
    else
      nil
    end
  end
  
  # TODO - get rid of these methods
  def get_entity(xpath)
    @xw.lookup_entity_for(xpath)
  end


  def get_property(type, xpath)
    @xw.lookup_property_for(type, xpath)

  end

end

