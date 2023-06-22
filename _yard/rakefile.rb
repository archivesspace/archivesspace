namespace :doc do

  desc "Generate the documentation"
  task :yard do
    puts "Generating YARD documentation"
    system(File.join("..", "build", "run"), "doc:yardoc")
  end


  desc "Create the API.md file"
  task :api do
    puts "Creating the API.md file"
    require 'erb'
    require 'sinatra'
    require 'jsonmodel'
    require_relative '../backend/app/lib/rest.rb'
    require_relative '../backend/app/lib/username.rb'
    require_relative '../backend/app/model/backend_enum_source.rb'
    require_relative '../common/log.rb'
    require_relative '../backend/app/lib/streaming_import.rb'
    require_relative '../backend/app/lib/component_transfer.rb'


    class ArchivesSpaceService < Sinatra::Base

      def self.helpers
        nil
      end

      include RESTHelpers

    end

    @time = Time.new

    JSONModel::init(:enum_source => BackendEnumSource)

    require_relative '../backend/app/lib/export'

    Dir.glob(File.dirname(__FILE__) + '/../backend/app/controllers/*.rb').sort.each {|file| require file unless (file =~ /system/ || file =~ /oai/)}

    @endpoints = ArchivesSpaceService::Endpoint.all.sort{|a,b| a[:uri] <=> b[:uri]}
    @examples = JSON.parse( IO.read File.dirname(__FILE__) + "/../endpoint_examples.json" )


    erb = ERB.new(File.read('API.erb'), nil, '<>')

    File.open('../API.md', 'w') do |f|
      f.write erb.result(binding)
    end

  end

  desc 'Produce an OpenAPI yaml spec from endpoint definitions'
  task :generate_openapi do
    require 'erb'
    require 'sinatra'
    require 'jsonmodel'
    require 'set'
    require_relative '../backend/app/lib/rest.rb'
    require_relative '../backend/app/lib/username.rb'
    require_relative '../backend/app/model/backend_enum_source.rb'
    require_relative '../common/log.rb'
    require_relative '../backend/app/lib/streaming_import.rb'
    require_relative '../backend/app/lib/component_transfer.rb'


    class ArchivesSpaceService < Sinatra::Base

      def self.helpers
        nil
      end

      include RESTHelpers

    end

    @time = Time.new

    JSONModel::init(:enum_source => BackendEnumSource)

    require_relative '../backend/app/lib/export'

    Dir.glob(File.dirname(__FILE__) + '/../backend/app/controllers/*.rb').sort.each {|file| require file unless (file =~ /system/ || file =~ /oai/)}

    @endpoints = ArchivesSpaceService::Endpoint.all.sort{|a,b| a[:uri] <=> b[:uri]}
    @examples = JSON.parse( IO.read File.dirname(__FILE__) + "/../endpoint_examples.json" )
    @models = JSONModel.models.map {|name, model| [name, Marshal.load(Marshal.dump(model.schema))]}.to_h


    open_api_spec = {
      openapi: "3.1.0",
      info: {
        title: "ArchivesSpace API",
        version: "0.0.1",
        description: "API for ArchivesSpace"
      }
    }

    # Components - regularize to actual JSONSchema types and ref structure, do type first
    @type_re = /\AJSONModel\(:(?<type>[^)]+)\) (?<kind>.*)\z/
    @property_keys = Set.new(['additionalProperties', 'properties'])

    def handle_type(type)
      out = {}
      (type.is_a?(Array) ? type : [type]).each do |type|
        if type.is_a? Hash
          correct_type(type)
          return type
        end
        out['type'] ||= []
        if m = type.match(@type_re)
          out['aspace_original_type'] ||= []
          out['aspace_original_type'] << type

          case m['kind']
          when 'uri'
            out['type'] << 'string'
          when 'object'
            out['type'] << "#/components/schemas/#{m['type']}"
          when 'uri_or_object'
            out['type'] << {'anyOf' => ['string', "#/components/schemas/#{m['type']}"]}
          else
            puts "unknown kind of type: #{m['kind']}"
            out['type'] << type
          end
        else
          out['type'] << type
        end
      end
      if out['type'].count == 1
        out['type'] = out['type'].first
      end
      if out['aspace_original_type'] && out['aspace_original_type'].count == 1
        out['aspace_original_type'] = out['aspace_original_type'].first
      end
      out
    end

    def correct_type(obj)
      if obj.is_a? Array
        obj.each do |v| correct_type(v) end
      elsif obj.is_a? Hash
        if obj.include?('type')
          obj.merge!(handle_type(obj['type']))
        end

        obj.each do |key, val|
          if @property_keys.include? key
            correct_type(obj[key].values)
          end
          if key === "items"
            correct_type(obj[key])
          end
        end
      end
    end


    @models.values.each do |v| correct_type(v) end

    # paths - Endpoints



    require "pry"
    binding.pry
  end

  desc 'Rename the YARD index file to avoid problems with Jekyll'
  task :rename_index do
    puts "Renaming the YARD index file"
    Dir.chdir('../docs') do
      files = Dir.glob('doc/**/*')
      files.each do |f|
        if File::file?(f)
          content = File.read(f)
          content.gsub!('"_index.html"', '"alpha_index.html"')
          content.gsub!('/_index.html', '/alpha_index.html')
          File.open(f, "w") do |io|
            io.write content
          end
        end
      end
      `mv doc/_index.html doc/alpha_index.html`
    end
  end

  desc 'This generates all documentation and publishes it to the doc folder'
  task :gen do
    require 'fileutils'

    puts "Removing old documentation"
    FileUtils.rm_rf("./docs/doc")

    Rake::Task["doc:api"].invoke
    Rake::Task["doc:yard"].invoke
    Rake::Task["doc:rename_index"].invoke

    puts "Updating API documentation"
    FileUtils.cp("../API.md", "../docs/slate/source/index.md")
  end


end
