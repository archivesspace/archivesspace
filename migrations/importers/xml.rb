require 'psych'
require 'nokogiri'
require 'rufus-lru'

ASpaceImport::Importer.importer :xml do

  def debugging?
    $DEBUG
  end


  def initialize(opts)

    # TODO:
    # validate(opts[:input_file]) 
    
    hack_input_file_for_nokogiri_exceptions(opts)

    @reader = Nokogiri::XML::Reader(IO.read(opts[:input_file]))
    @regex_cache = Rufus::Lru::Hash.new(10000)
    @attr_selectors = []
    
    # Allow JSON Models to hold some Nokogiri info
    ASpaceImport::Crosswalk.models.each do |key, model|
      model.class_eval do
        attr_accessor :depth
        attr_accessor :xpath
      end
    end
    
    # Allow Nokogiri nodes to hold their path
    Nokogiri::XML::Reader.class_eval do
      attr_accessor :xpath
    end
    
    # Make objects less promiscuous linkers when they're sitting in 
    # the parse queue: 
    ASpaceImport::Crosswalk.add_link_condition(lambda { |r, json|

      if r.class.xdef['axis'] && r.class.valid_json_types.include?(json.jsonmodel_type)
      
        return Proc.new {|axis, offset|
          if (axis == 'parent' && offset == 1) || \
             (axis == 'ancestor' && offset >= 1) || \
             (axis == 'descendant' && offset <= -1 ) || \
             (axis == 'self' && offset == 0)
            true
          else
            false
          end
        }.call(r.class.xdef['axis'], r.object.depth - json.depth)      

      else
        # Fall back to testing the other object's source node
        return false unless r.class.xdef['xpath']

        offset = json.depth - r.object.depth
        xpath_regex = regexify(json.xpath, offset)
        
        # use caching to limit regex matching
        unless r.cache.has_key?(xpath_regex)
          r.cache[xpath_regex] = r.class.xdef['xpath'].find { |xp| xp.match(xpath_regex) } ? true : false
        end
        
        r.cache[xpath_regex]
      end
    })
    
    set_up_tracer if debugging?
      
    super

  end


  def self.profile
    "Imports XML-encoded data using Nokogiri::XML::Reader"
  end


  def run

    @reader.each do |node|

      add_xpath(node)

      node.start_trace if debugging?

      case node.node_type

      when 1
        handle_opener(node)        
      when 3
        handle_text(node)
      when 15
        handle_closer(node)
      end
    end
    
    save_all
    
  end  

  def handle_opener(node)
    
    if object_raised_by node
      parse_queue.with_raised { get_data_from node }
    else
      parse_queue.select_each_and { get_data_from node }
    end
  end
  
  def handle_text(node)
    
    parse_queue.select_each_and { get_data_from node }        
  end
  
  def handle_closer(node)
    
    if object_raised_by node
      parse_queue.raised.reverse.each do |rsd| 
        raise "Unexpected Object Type in Queue" unless rsd = parse_queue.last
        
        rsd.set_default_properties
        parse_queue.pop
      end
      
      parse_queue.unraise_all  
      
    
      # parse_queue.last.set_default_properties

      # parse_queue.pop
    end
  end
  
  def get_data_from(node)
    
    # extract data from selfsame node


    if node.depth == parse_queue.selected.depth

      parse_queue.selected.receivers.each do |r|
        
        if (xp_list = r.class.xdef['xpath'])
          if xp_list.find {|xp| xp == "self"}
            r << node.inner_xml
          elsif xp_list.find {|xp| xp == "self::name"}
            r << node.name
          end
          
          node.attributes.each do |a|
            if xp_list.find {|xp| xp == "@#{a[0]}"}
              r << a[1]
            end
          end
        end
      end
    # extract data from a descendant or ancestor node 
    else

      offset = node.depth - parse_queue.selected.depth
      xpath_regex = regexify(node.xpath, offset)
      
      parse_queue.selected.receivers.each do |r|

        next unless r.class.xdef['xpath']
        
        if r.class.xdef['xpath'].find { |xp| xp.match(xpath_regex) } 
          if node.node_type == 1
            r << node.inner_xml 
          elsif node.node_type == 3
            r << node.value.sub(/[\s\n]*$/, '')
          else 
            raise "Attempted to get data from an unhandleable node type"
          end
        end
      end
    end
  end
  
  
  def object_raised_by(node)
    
    parse_queue.unraise_all

    types = get_types_for_node(node)

    if !types.empty?

      if node.node_type == 1

        types.each do |type|

          json = ASpaceImport::Crosswalk.models[type].new

          json.xpath, json.depth = node.xpath, node.depth

          $tracer.trace(:aspace_data, json, nil) if debugging?

          parse_queue.push_and_raise(json)
        end

      else

        types.reverse.each_with_index do |t, i|
          # Just a sanity check
          raise "Record Type mismatch in parse queue" unless parse_queue[(i+1)*-1].class.record_type == ASpaceImport::Crosswalk.models[t].record_type
          parse_queue.raised.push(parse_queue[(i+1)*-1])
        end

      end
      true
    else
      false
    end
  end
  
  
  def validate(input_file)
    
    # open(input_file).read().match(/xsi:schemaLocation="[^"]*(http[^"]*)"/)
    # 
    # require 'net/http'
    # 
    # uri = URI($1)
    # xsd_file = Net::HTTP.get(uri)
    # 
    # xsd = Nokogiri::XML::Schema(xsd_file)
    # doc = Nokogiri::XML(File.read(input_file))
    # 
    # xsd.validate(doc).each do |error|
    # end
  
  end
  

  def get_types_for_node(node)
    regex = regexify(xpath(node))

    if (types = ASpaceImport::Crosswalk.entries.map {|k,v| k if v["xpath"] and v["xpath"].find {|x| x.match(regex)}}.compact)
      return types
    else
      return nil
    end
  end

  
  # Returns a regex object that is used to match the xpath of a 
  # parsed node with an xpath definition in the crosswalk. In the 
  # case of properties, the offset is the depth of the predicate 
  # node less the depth of the subject node. An offset of nil
  # indicates a root perspective.
  
  def regexify(xp, offset = nil)
    
    atts = @attr_selectors || []
    
    # Slice the xpath based on the offset
    # escape for `text()` nodes
    unless offset.nil? || offset < 1
      xp = xp.scan(/[^\/]+/)[offset*-1..-1].join('/')
      xp.gsub!(/\(\)/, '[(]{1}[)]{1}')
    end
    
    # TODO: chop out the irrelevant attrs before making the key
    key = "#{xp}#{atts.to_s}#{offset}"
    
    unless @regex_cache[key]
    
      case offset
      
      when nil
        @regex_cache[key] ||= Regexp.new "^(/|/" << xp.split("/")[1..-2].map { |n| 
                                "(child::)?(#{n}|\\*)" 
                                }.join('/') << ")" << xp.gsub(/.*\//, '/') \
                                << (atts.last ? atts.last.map {|k,v| "(\\[#{k.to_s}='#{v}'\\])?"}.join : "") \
                                << "$"
      
      when 0
        @regex_cache[key] ||= /^[\/]?#{xp.gsub(/.*\//, '')}$/

      when 1..100
      
        ns = []
        xp.scan(/[a-zA-Z_]+/)[offset*-1..-2].each_with_index do |n, i|
      
          j = offset + i
          if atts[j] && !atts[j].empty?
            atts[j].each {|k,v| n += "(\\[#{k.to_s}='#{v}'\\])?"}
          end
          
          ns << "(child::)?(#{n}|\\*)"
        end
      
      
        @regex_cache[key] ||= Regexp.new "^(descendant::|" << ns.join('/') \
                                                           << (offset > 1 ? "/" : "") \
                                                           << "(child::)?)" \
                                                           << xp.gsub(/.*\//, '') \
                                                           << (atts.last ? atts.last.map {|k,v| "(\\[#{k.to_s}='#{v}'\\])?"}.join : "")\
                                                           << "$"

    
      when -100..-1
        @regex_cache[key] ||= Regexp.new "^(ancestor::|" << ((offset-1)*-1).times.map {
                                  "parent::\\*/"
                                  }.join << "parent::)#{xp.gsub(/.*\//, '')}"
      end
    end

    @regex_cache[key]
    
  end
  
  private
  
  
  def add_xpath(node)
    node.instance_variable_set("@xpath", xpath(node))
  end
        
  
  # Builds a full path to the node
  def xpath(node)
    
    @xpath ||= '/'
    @depth ||= 0
    @attr_selectors[node.depth] = {}
    
    while @attr_selectors.last != @attr_selectors[node.depth]
      @attr_selectors.slice!(-1)
    end
    
    name = node.name.gsub(/#text/, "text()")
    node.attributes.each do |a|
      @attr_selectors[@depth]["@#{a[0]}"] = a[1]
    end

    if @depth < node.depth
      @xpath.concat("/#{name}")
    elsif @depth == node.depth
      @xpath.sub!(/\/[#()a-z0-9]*$/, "/#{name}")
    elsif @depth > node.depth
      @xpath.sub!(/\/[#()a-z0-9]*\/[#()a-z0-9]*$/, "/#{name}")
    else
      raise "Can't parse node depth to create XPATH"
    end

    @depth = node.depth
    @xpath.clone
  end
  
  # Development / Debugging stuff
  
  def set_up_tracer
    require 'tmpdir'
    $tracer = Tracer.new

    
    Nokogiri::XML::Reader.class_eval do
      alias_method :inner_xml_original, :inner_xml

      def start_trace
        $tracer.set_node(self)
      end

      def inner_xml
        $tracer.trace(:inner_xml, inner_xml_original)
        inner_xml_original
      end
          
    end
    
    ASpaceImport::Crosswalk::PropertyReceiver.class_eval do
      alias_method :receive_original, :receive
      
      def receive(val = nil)
        if receive_original(val)
          set_val = @object.send("#{self.class.property}") 
          if set_val.is_a? String
            received_val = @object.send("#{self.class.property}")
          elsif set_val and set_val.is_a? Array
            received_val = @object.send("#{self.class.property}").last
          end

          $tracer.trace(:aspace_data, @object, self.class.property, received_val)
        end
      end
    end
    
    ASpaceImport::Importer.class_eval do
      alias_method :save_all_original, :save_all
      
      def save_all
        uri_map = {}
        response = @parse_queue.save
        
        if response.code.to_s == '200'
          JSON.parse(response.body)['saved'].each do |k,v|
            uri_map[k] = v
          end
          $tracer.out(uri_map)
        end  
        
        log_save_result(response)
      end
    end
    
  end

  
  def hack_input_file_for_nokogiri_exceptions(opts)
    
    # Workaround for Nokogiri bug:
    # https://github.com/sparklemotion/nokogiri/pull/805
    
    new_file = File.new(opts[:input_file].gsub(/\.xml/, '_no_xlink.xml'), "w")
    
    File.open opts[:input_file], 'r' do |f|
      f.each_line do |line|
        new_file.puts line.gsub(/\sxlink:href=\".*?\"/, "")
      end
    end
    
    new_file.close
    
    opts[:input_file] = new_file.path
  end

end

class Tracer
  attr_accessor :registry
  
  def initialize(tfile = File.new("#{Dir.tmpdir}/ead-trace.tsv", "w"))
    @file = tfile
    @index, @registry = 0, []
  end
  
  def set_node(node)
    @index += 1 unless @index == 0 and @registry.length == 0
    @registry[@index] = {
                          :node_type => node.node_type, 
                          :node_value => node.value? ? node.value.sub(/[\s\n]*$/, '') : nil,
                          :xpath => node.xpath,
                          :aspace_data => [],
                          :inner_xml => []
                        }
  end

  
  def trace(key, *j, val)
    json, prop = j

    val = sanitize(val)

    if json and json.class.method_defined? :uri
      ref = prop ? "#{json.uri}\##{prop}" : "#{json.uri}"
    elsif json
      ref = prop ? "#{json.class.to_s}\##{prop}" : "#{json.class.to_s}"
    end

    if key == :aspace_data
      @registry[@index][key] << [ref, val]
    else
      @registry[@index][key] << val
    end
  end
  
  def sanitize(val)

    return if val.nil? 
    return val if val.is_a?(Hash)

    if val.class.method_defined? :uri
      val = val.uri
    end

    val.gsub!(/^\s*/, '')
    val.gsub!(/\s*$/, '')
    val.gsub!(/[\t\n\r]/, '')

    val
  end
  
  def out(map = {})
    @file.write(%w(00000 NODE.TYPE XPATH NODE.XML NODE.TEXT ASPACE.REF ASPACE.VAL).join("\t").concat("\n"))
    @registry.each_with_index do |l, i|

      [1, l[:aspace_data].length].max.times do |j|
        
        if l[:aspace_data][j].is_a?(Array)
          aspace_data = "#{l[:aspace_data][j][0]}\t#{l[:aspace_data][j][1]}"
        else
          aspace_data = "\t"
        end
        
        if j == 0
          line = "#{'%05d' % i}-#{j}\t#{l[:node_type]}\t#{l[:xpath]}\t#{l[:inner_xml][j]}\t#{l[:node_value]}\t#{aspace_data}\n"
        else
          line = "#{'%05d' % i}-#{j}\t\t\t#{l[:inner_xml][j]}\t\t#{aspace_data}\n"
        end
        map.each do |posted_uri, actual_uri|
          line.gsub!(posted_uri, actual_uri)
        end
      
        @file.write(line)
      end
    end
  end 
end   

