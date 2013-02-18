require 'psych'
require 'nokogiri'

ASpaceImport::Importer.importer :xml_dom do

  def initialize(opts)

    # hack_input_file_for_nokogiri_exceptions(opts)

    @document = Nokogiri::XML::Document.parse(IO.read(opts[:input_file]))
      
    super

  end


  def self.profile
    "Imports XML-encoded data using Nokogiri::XML::Document"
  end


  def run
    
    ASpaceImport::Crosswalk.entries.each do |key, defn|
    
      next unless defn['xpath']
      
      defn['xpath'].each do |xp|
        
        make_objects(@document, xp, parse_queue, ASpaceImport::Crosswalk.models[key])
      end
    end 

    puts parse_queue.inspect

    # TODO: This is a little screwy - sending 'save'
    # to a full parse queue does nothing.
    clear_parse_queue    
    save_all

  end
    
  def make_objects(node, xpath, destination, klass)
    node.xpath(xpath, @document.root.namespaces).each do |node|
      obj = klass.new
      obj.receivers.each do |r|
        if r.class.property_type.match /^record/
          r.class.xdef['xpath'].each do |xp|
            make_objects(node, xp, r, ASpaceImport::Crosswalk.models[r.class.xdef['record_type']])
          end
        elsif r.class.xdef.has_key?('xpath')
          r.class.xdef['xpath'].each do |xp|
            do_property_stuff(node, xp, r)
          end
        end
      end
      obj.set_default_properties
      
      destination << (obj) 
    end
  end
  
  def do_property_stuff(node, xp, destination)
    node.xpath(xp, @document.root.namespaces).each do |node|
      destination << node.inner_text
    end
  end

end

   

