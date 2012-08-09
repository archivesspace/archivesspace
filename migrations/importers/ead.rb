require 'nokogiri'

ASpaceImporter.importer :ead do
  def self.profile
    "Default EAD importer. Takes 1 argument: EADFILE"
  end
  def run
    if ARGV[0] == nil
      raise ArgumentError.new("Need FILE argument (a path to a file)")
      # TODO - make sure it's really a file
    end
    input_file = ARGV[0]
    reader = Nokogiri::XML::Reader(IO.read(input_file))
    
    reader.each do |node|
      #TODO - Error handling - missing tags
      if node.node_type == 1 and node.name == 'eadheader'
        puts "Reading <eadheader>" if $DEBUG
        node.read until node.name == 'eadid'
        stash :eadid, node.inner_xml
      end
      if node.node_type == 1 and node.name == 'archdesc'
        puts "Reading <archdesc>" if $DEBUG
        node.read until node.name == 'unittitle'
        stash :title, node.inner_xml
        open_new :collection, { :eadid => grab(:eadid), :title => grab(:title) }
        puts "Created collection #{ current :collection }." if $DEBUG
      end
  
      # Container List
      # ASpace data model requires a root archival object to wrap the collection
      if node.node_type == 1 and node.name == 'dsc'
        puts "Reading <dsc>" if $DEBUG
        open_new :archival_object, { 
                                    :id_0 => 'dsc', 
                                    :title => 'Root Archival Object',
                                    :level => 'dsc'
                                    }
      end

      if node.node_type == 1 and node.name == 'c'
        puts "Reading <c>: Depth #{node.depth()}" if $DEBUG
      
        ao_hsh = Hash.new
        stash :id_0, node.attribute_at(0)
        stash :level, node.attribute_at(1)
        node.read until node.name == 'unittitle'
        stash :title, node.inner_xml
        open_new :archival_object, { 
                                    :id_0 => grab(:id_0),
                                    :title => grab(:title),
                                    :level => grab(:level)
                                    }



      end
      
      if node.node_type != 1 and node.name == 'c'
        puts "Read </c>: Depth #{node.depth()}" if $DEBUG
        close :archival_object
      end
    end
  end
end

