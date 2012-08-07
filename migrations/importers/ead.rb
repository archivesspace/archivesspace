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
    
    @open_objects = Array.new 
    @coll_hsh = Hash.new
    
    reader.each do |node|
      #TODO - Error handling - missing tags
      if node.node_type == 1 and node.name == 'eadheader'
        puts "Reading <eadheader>" if $DEBUG
        
        node.read until node.name == 'eadid'
        @coll_hsh[:id_0] = node.inner_xml
      end
      if node.node_type == 1 and node.name == 'archdesc'
        puts "Reading <archdesc>" if $DEBUG
        node.read until node.name == 'unittitle'
    
        @coll_hsh[:title] = node.inner_xml
        #Import the collection
        res = import :collection, @coll_hsh
        @coll_hsh[:id] = res[:id]
      end
  
      #Container List
      if node.node_type == 1 and node.name == 'dsc'
        puts "Reading <dsc>" if $DEBUG
      end

      if node.node_type == 1 and node.name == 'c'
        depth = node.depth()
        puts "Reading <c>" if $DEBUG
        puts "Depth #{depth}" if $DEBUG
      
        ao_hsh = Hash.new
        @ao_params = Hash.new
        @ao_params[:collection] = @coll_hsh[:id]
        ao_hsh[:id_0], ao_hsh[:level] = node.attribute_at(0), node.attribute_at(1)
        node.read until node.name == 'unittitle'
        ao_hsh[:title] = node.inner_xml
        #Wrap if this object has a parent
        if @open_objects[depth-1] && @open_objects[depth-1].has_key?(:id)
          puts @open_objects[depth-1].inspect
#          @open_objects[depth-1]["wraps"].push(ao_hsh["id"])   # revist if/when shema includes children
          @ao_params[:parent] = @open_objects[depth-1][:id].to_i
        end
        @open_objects[depth] = ao_hsh


      end
      if node.node_type != 1 and node.name == 'c'
        depth = node.depth()
        puts "Read </c>" if $DEBUG
        puts "Depth #{depth}" if $DEBUG
        # Close the arch object
        @open_objects[depth].delete_if { |k, v| v.empty? }
        puts @open_objects[depth].inspect
        puts @ao_params.inspect
        res = import :archival_object, @open_objects[depth], @ao_params
        @open_objects[depth][:id] = res[:id]
        #Close an Object
      end
    end
  end
end

