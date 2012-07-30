#!/usr/bin/env ruby
require_relative File.join("..", "..", "common", "jsonmodel")

class ASpaceImporter
  include JSONModel
  @@importers = { }
  def self.register_importer name
    @@importers[name] = self
  end
  def self.create_importer name
    i = @@importers[name]
    if i
      i.new
    else
      puts "Bad importer type or importer not found for: #{name}"
    end
  end
  def self.importer name, superclass=ASpaceImporter, &block
    c = Class.new(superclass, &block)
    c.register_importer(name)
    Object.const_set("#{name.to_s.capitalize}ASpaceImporter", c)
  end
  
  def import(type, hsh)
    #Make sure the type is importable, i.e., that it has a class
    puts type
    puts ALLOWFAILURES
    begin
      if JSONModel(type) 
        puts JSONModel(type).name
      else
        raise ArgumentError.new("Don't know how to import a #{type}")
      end
      #make sure hsh is a hash
      if hsh.is_a?(Hash)
      else
        raise ArgumentError.new("Expected a Hash got #{hsh}") #TODO rescue and continue if opted for
      end    
      puts "Importing #{hsh.to_json}"
      jo = JSONModel(type).from_hash(hsh)
      puts "Here it is: #{jo.to_json}"
    rescue ArgumentError => e
      if ALLOWFAILURES
        puts "Warning: #{e.message}"
      else
        raise e
      end
    end

    
  end
  


end



