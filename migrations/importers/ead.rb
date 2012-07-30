# written for Ruby 1.9.3

require 'nokogiri'
#require_relative File.join("..", "..", "common", "jsonmodel")


class Importer
  include JSONModel
  def read(input_file)
    @asrp = ASpaceRecordPoster.new()

    reader = Nokogiri::XML::Reader(IO.read(input_file))
    
    @open_objects = Array.new 
    @coll_hsh = Hash.new
    
    reader.each do |node|
      #TODO - Error handling - missing tags
      if node.node_type == 1 and node.name == 'eadheader'
        puts "Reading <eadheader>" if $DEBUG
        
        node.read until node.name == 'eadid'
        @coll_hsh["id"] = node.inner_xml
      end
      if node.node_type == 1 and node.name == 'archdesc'
        puts "Reading <archdesc>" if $DEBUG
        node.read until node.name == 'unittitle'
    
        @coll_hsh["title"] = node.inner_xml
        #Post the collection
        co = JSONModel(:collection).from_hash(@coll_hsh)
        @asrp.post_json('collection', co.to_json)
      end
  
      #Container List
      if node.node_type == 1 and node.name == 'dsc'
        puts "Reading <dsc>" if $DEBUG
      end



      if node.node_type == 1 and node.name == 'c'
        depth = node.depth()
        puts "Reading <c>" if $DEBUG
        puts "Depth #{depth}" if $DEBUG
      
        #ao = ArchivalObject.new
        ao_hsh = Hash.new
        ao_hsh["wraps"] = Array.new
        ao_hsh["id"], ao_hsh["level"] = node.attribute_at(0), node.attribute_at(1)
        node.read until node.name == 'unittitle'
        ao_hsh["title"] = node.inner_xml
        #Wrap if this object has a parent
        if defined? @open_objects[depth-1]["id"]
          puts @open_objects[depth-1]["title"]
          @open_objects[depth-1]["wraps"].push(ao_hsh["id"])
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
        ao = JSONModel(:archival_object).from_hash(@open_objects[depth])
        puts "Created a JSON record object for #{ao.title}" if $DEBUG
        
        @asrp.post_json('archival object', ao.to_json)

        #Close an Object
      end
    end
  end
end

