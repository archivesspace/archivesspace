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
  def self.create_importer options
    i = @@importers[options[:importer].to_sym]
    if i
      i.new options
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
  
  def initialize opts
    @relaxed, @verbose, @dry, @repo = opts[:relaxed], opts[:verbose], opts[:dry], opts[:repo]
    @goodimports = 0
    @badimports = 0   
  end
  
  def report
    puts "#{@goodimports} records successfully imported"
    puts "#{@badimports} records failed to import"
  end
       
  def import(type, hsh, params = { })
    @response = nil
    begin
      if JSONModel(type) 
      else
        raise ArgumentError.new("Don't know how to import a #{type}")
      end
      if hsh.is_a?(Hash)
      else
        raise ArgumentError.new("Expected a Hash got #{hsh}")
      end    
      puts "Importing #{hsh.to_json}" if @verbose
      jo = JSONModel(type).from_hash(hsh)
      if @dry
        puts "(Not) Posting to #{ASpaceImportConfig::ASPACE_HOST}:#{ASpaceImportConfig::ASPACE_PORT} #{jo.to_json}"
        @goodimports += 1
        {'id' => 999}
      else
        # Post data to ASpace
        case type
        when :repository
          puts "Posting a Repository" if @verbose
          opts = {:body => {'repository' => jo.to_json } }
          @response = ASpaceParty.post('/repository', opts)
        when :collection
          puts "Posting a Collection" if @verbose
          opts = {:body => params.merge('collection' => jo.to_json)}
          @response = ASpaceParty.post('/collection', opts)
        when :resource
          puts "Posting a Resource" if @verbose
        when :archival_object
          puts "Posting an Archival Object" if @verbose
          opts = {:body => params.merge('archival_object' => jo.to_json)}
          @response = ASpaceParty.post('/archival_object', opts)
          puts @response.insepect if $DEBUG
        else
          puts "This error should never happen, type = #{type}"
        end 
        if defined? @response.parsed_response['id']
          @goodimports += 1
          {:id => @response.parsed_response['id']}
        else
          @badimports += 1
          raise Exception.new("Can't identify the ID returned by ASpace")
        end        
      end
    rescue ArgumentError => e
      if @relaxed
        puts "Warning: #{e.message}"
        @badimports += 1
      else
        raise e
      end
    end

    
  end
  


end



