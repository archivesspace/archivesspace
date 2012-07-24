# written for Ruby 1.9.3

require 'nokogiri'
require 'json'

input_file = ARGV[0]

class ASpaceRecordPoster
  def post_json(record_type, json_record)
    #TODO - Work out the POST URL by the record type
    #TODO - config for ASPACE host, port, repository, auth info
    #TODO - get back an ID and confirmation from ASpace
    puts "Posting new '#{record_type}' to ASpace:" 
    puts json_record;
  end
end

class ASpaceRecord
  def to_s
    "Placeholder of the Record as String"
  end
  def to_json
       hash = {}
       self.instance_variables.each do |var|
           hash[var[1..-1]] = self.instance_variable_get var
       end
       #TODO - Match ASpace schemas, validate
       hash.to_json
   end
end

class Collection < ASpaceRecord
  def title=(title)
    @title = title
  end
  def eadid=(eadid)
    @eadid = eadid
  end
end

class ArchivalObject < ASpaceRecord
  def initialize()
    @wrapped_objects = Array.new
  end
  def title=(title)
    @title = title
  end
  def id=(id)
    @id = id
  end
  def id 
    @id
  end
  def level=(level)
    @level = level
  end
  def wrap(archival_object)
    @wrapped_objects << archival_object.id
  end
  def to_s
    puts "#{@id}: #{@title}"
  end 
end


class EADReader
  def read(input_file)
    @asrp = ASpaceRecordPoster.new()

    reader = Nokogiri::XML::Reader(IO.read(input_file))
    
    @open_objects = Array.new 
    @coll = Collection.new()
    
    reader.each do |node|
      #TODO - Error handling - missing tags
      #TODO - get rid of global vars
      if node.node_type == 1 and node.name == 'eadheader'
        puts "Reading <eadheader>" if $DEBUG
        
        node.read until node.name == 'eadid'
        @coll.eadid = node.inner_xml
      end
      if node.node_type == 1 and node.name == 'archdesc'
        puts "Reading <archdesc>" if $DEBUG
        node.read until node.name == 'unittitle'
    
        @coll.title = node.inner_xml
        #Post the collection
        @asrp.post_json('collection', @coll.to_json)
      end
  
      #Container List
      if node.node_type == 1 and node.name == 'dsc'
        puts "Reading <dsc>" if $DEBUG
      end



      if node.node_type == 1 and node.name == 'c'
        #If an object is already open, push it out of the way
        #Open an object
        depth = node.depth()
        puts "Reading <c>" if $DEBUG
        puts "Depth #{depth}" if $DEBUG

        #$open_objects[depth] = nil
        ao = ArchivalObject.new
        ao.id, ao.level = node.attribute_at(0), node.attribute_at(1)
        node.read until node.name == 'unittitle'
        ao.title = node.inner_xml
        puts ao.id if $DEBUG
        #Wrap if this object has a parent
        if defined? @open_objects[depth-1].id
          puts "ID #{ao.id} d" if $DEBUG
          @open_objects[depth-1].wrap(ao)
        end
        @open_objects[depth] = ao


      end
      if node.node_type != 1 and node.name == 'c'
        depth = node.depth()
        puts "Read </c>" if $DEBUG
        puts "Depth #{depth}" if $DEBUG
        # Close the object
        @asrp.post_json('archival object', @open_objects[depth].to_json)

        #Close an Object
      end
    end
  end
end


e = EADReader.new
e.read(input_file)

