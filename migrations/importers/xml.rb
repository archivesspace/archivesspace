require 'psych'
require 'nokogiri'

ASpaceImport::Importer.importer :xml do

  def initialize(opts)
    # load in the YAML
    # TODO - die if not given a crosswalk and an input file
    # TODO - require gems at run time? (so it can be listed without giving an error)
    @walk = Psych.load(IO.read(opts[:crosswalk]))
    @reader = Nokogiri::XML::Reader(IO.read(opts[:input_file]))
    super
  end


  def self.profile
    "XML pull parser for use with a YAML crosswalk"
  end


  def run
    @reader.each do |node|
      #open tag
      if node.node_type == 1
        if (jo = JSONModel(lookup_entity_for(node.name)).new)
          node.attributes.each do |att|
            property = lookup_property_for(jo.class.record_type, att[0])    
            if jo.respond_to?(property)
              unless jo.send("#{property}") # don't set the property more than once
                jo.send("#{property}=", att[1])
              end
            else
              raise StandardError.new("Can't set #{property} on #{@jo.class.to_s}")
            end
          end
          # We queue once we are finished with an opening tag
          jo.queue
        elsif (jo = JSONModel::Client.queue.last)
            jo.send("#{lookup_property_for(jo.class.record_type, node.name)}=", node.inner_xml)
        end
      #close tag
      elsif node.node_type != 1 
        if (jo = JSONModel::Client.queue[-1])
          type = lookup_entity_for(node.name)
          raise StandardError.new("type mismatch") unless jo.class.record_type == type           
        #is there an ancestor or parent dependency?
          @walk['entities'][type]['properties'].each do |prop, xpaths|
            xpaths.each do |xp|
              if xp.match(/^parent::([a-z]*)$/)
                parent_type = lookup_entity_for($1)
                # if the current node calls for something on the parent axis, 
                # that should be the last-1 item in the queue
                if (pjo = JSONModel::Client.queue[-2])
                  raise StandardError.new("type mismatch") unless pjo.class.record_type == parent_type 
                  pjo.add_save_hook(Proc.new { jo.send("#{prop}=", pjo.uri) })
                  jo.add_reference(pjo)
                end
              end  
            end
          end
          jo.dequeue #Save or 
        end
      end
    end
  end
  
  # TODO - move these methods to the Crosswalk class.
  def lookup_entity_for(xpath)
    types = []
    @walk['entities'].each do |k, v|
      v['instance'].each do |xp|
        if xp.match(/(\/)*#{xpath}$/)
          types.push(k)
        end
      end
    end
    if types.count > 1
      raise StandardError.new("Found more than one entity to create with this xpath, and have no means of giving them priority: #{types.to_s}")
    else
      types.pop
    end
  end


  def lookup_property_for(type, xpath)
    return nil unless @walk['entities'][type]
    properties = []
    @walk['entities'][type]['properties'].each do |property, xpaths|
      xpaths.each do |xp|
        if xp.match(/^(\/)*(@)?#{xpath}$/)
          properties.push(property)
        end
      end
    end
    if properties.count > 1
      raise StandardError.new("Found more than one property to create with this xpath, and have no means of giving them priority: #{properties.to_s}")
    else
      properties.pop
    end
  end

end