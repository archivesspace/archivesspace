require 'psych'
require 'nokogiri'

ASpaceImporter.importer :xmlpull do

  def initialize(opts)
    # load in the YAML
    # TODO - die if not given a crosswalk and an input file
    # TODO - require gems at run time? (so it can be listed without giving and error)
    @walk = Psych.load(IO.read(opts[:crosswalk]))
    @reader = Nokogiri::XML::Reader(IO.read(opts[:input_file]))
    super
  end
    
  def self.profile
    "XML pull parser for use with a YAML crosswalk"
  end
  
  def run
    @reader.each do |node|
      if node.node_type == 1
        if @json_queue.push(lookup_entity_for(node.name))
          type = @json_queue.last.class.record_type #TODO - add method for this
          node.attributes.each do |att|            
            @json_queue.set_property(lookup_property_for(type, att[0]), att[1])
          end

        elsif @json_queue.length > 0
            type = @json_queue.last.class.record_type
            @json_queue.set_property(lookup_property_for(type, node.name), node.inner_xml)
        end
      end
      if node.node_type != 1
        type = lookup_entity_for(node.name)
        #is there an ancestor or parent dependency?
        if type
          @walk['entities'][type]['properties'].each do |prop, xpaths|
            xpaths.each do |xp|
              if xp.match(/^parent::([a-z]*)$/)
                parent_type = lookup_entity_for($1)
                # if the current node calls for something on the parent axis, 
                # that should be the last-1 item in the queue
                if @json_queue[-2].class.record_type == parent_type
                  @json_queue.set_property(prop, @json_queue[-2])
                end
              end
            end
          end
          @json_queue.pop
        end
      end
    end
  end
  
      
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