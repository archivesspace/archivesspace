#!/usr/bin/env ruby

puts "ASpace module"

#method for accessing an eigenclass
#class Object; def eigenclass; class << self; self end end end

module ASpaceImporter
  
  class ASpaceImporterNotFound < NameError; end
  class << self
    def create type 
      puts "Creating #{type}"
      puts "Registered handler: ok"
      puts self[type] 
      (self[type] ||= const_get("#{type.to_s.capitalize}ASpaceImporter").new)
    rescue NameError => e
      raise ASpaceImporterNotFound, "Bad importer type or importer not found for: #{type}" if e.class == NameError && e.message =~ /[^: ]ASpaceImporter/
      raise
    end
    
    def []=(type, klass)
      puts "Assiging #{type} to #{klass.name}"
      @importers ||= {type => klass}
      def []=(type, klass)
        @importers[type] = klass
      end
      klass
    end
    
    def [](type)
      @importers ||= {}
      def [](type)
        @importers[type]
      end
      nil
    end
    
    def included klass
      puts "Included method of the eigenclass"
      self[klass.name[/[[:upper:]][[:lower]]*/].downcase.to_sym] = klass if klass.is_a? Class
    end
    
    def test
      puts "This is a mixed in method"
    end
  end
end

def ASpaceImporter type
  puts "ASpaceImporter method #{type}"
  ASpaceImporter[type] = self.name
  ASpaceImporter
end




class ASpaceRecordPoster
  def post_json(record_type, json_record)
    #TODO - Work out the POST URL by the record type
    #TODO - config for ASPACE host, port, repository, auth info
    #TODO - get back an ID and confirmation from ASpace
    puts "Posting new '#{record_type}' to ASpace:" 
    puts json_record;
  end
end