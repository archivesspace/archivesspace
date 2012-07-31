#!/usr/bin/env ruby
#require 'net/http'
require 'httparty'

class ASpaceParty
  include HTTParty
  base_uri ASpaceImportConfig::ASPACE_BASE
end

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
    # TODO - Ensure the name / key hasn't been registered already
    c = Class.new(superclass, &block)
    c.register_importer(name)
    Object.const_set("#{name.to_s.capitalize}ASpaceImporter", c)
  end
  
  def self.list
    puts "The following importers are available"
    @@importers.each do |i, klass|
      puts "#{i} -- #{klass.name} -- #{klass.profile}"
    end
  end
    
  def import(type, hsh)
    puts type
    begin
      # Make sure the type is importable, i.e., that it has a model loaded
      if JSONModel(type) 
        puts "Preparing to import a #{JSONModel(type).name}" if VERBOSEIMPORT
      else
        raise ArgumentError.new("Don't know how to import a #{type}")
      end
      # Make sure hsh is really a Hash
      if hsh.is_a?(Hash)
      else
        raise ArgumentError.new("Expected a Hash got #{hsh}")
      end    
      puts "Importing #{hsh.to_json}" if VERBOSEIMPORT
      jo = JSONModel(type).from_hash(hsh)
      if DRYRUN
        puts "(Not) Posting to #{ASpaceImportConfig::ASPACE_HOST}:#{ASpaceImportConfig::ASPACE_PORT} #{jo.to_json}"
      else
        # Do the real post
        case type
        when :repository
          puts "Posting a Repository"
          opts = {:body => {'repository' => jo.to_json } }
#          opts = {:body => {'repository' => '{"repo_id": "dfgdfg", "description": "a new repository"}'} }
          res = ASpaceParty.post('/repository', opts)
          puts res.body
          puts res.headers.inspect
        when :resource
          puts "Posting a Resource"
        when :archival_object
          puts "Posting an Archival Object"
        else
          puts "This error should never happen, type = #{type}"
        end 

#        as = Net::HTTP.new(ASpaceImportConfig::ASPACE_HOST, ASpaceImportConfig::ASPACE_PORT)
#        as_url = "/#{type}"
#        @params = {"repo_id" => 1, "collection" => 1, "{type.gsub!(/_//)}" => "#{jo.to_json}"}
#        response = as.post_form(as_url, @params)
#        puts "Response from ASpace: #{response}"

      end
    rescue ArgumentError => e
      if ALLOWFAILURES
        puts "Warning: #{e.message}"
      else
        raise e
      end
    end

    
  end
  


end



