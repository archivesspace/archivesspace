namespace :doc do

  desc "Generate the documentation"
  task :yard do
    puts "Generating YARD documentation"
    system(File.join("..", "build", "run"), "doc:yardoc")
  end


  desc "Create the API.md and Schema files"
  task :api do
    require 'erb'
    require 'sinatra'
    require 'jsonmodel'
    require_relative '../backend/app/lib/rest.rb'
    require_relative '../backend/app/lib/username.rb'
    require_relative '../backend/app/model/backend_enum_source.rb'
    require_relative '../backend/app/lib/logging.rb'
    require_relative '../backend/app/lib/streaming_import.rb'
    require_relative '../backend/app/lib/component_transfer.rb'
    require_relative '../backend/app/lib/reports/report_helper.rb'


    class ArchivesSpaceService < Sinatra::Base
      
      def self.helpers
        nil
      end
      
      include RESTHelpers

    end
    
    @time = Time.new

    JSONModel::init(:enum_source => BackendEnumSource)
    
    

    require_relative '../backend/app/lib/export'

    Dir.glob(File.dirname(__FILE__) + '/../backend/app/controllers/*.rb') {|file| require file unless file =~ /system/}

    @models = JSONModel.models
    @endpoints = ArchivesSpaceService::Endpoint.all.sort{|a,b| a[:uri] <=> b[:uri]}
    @endpoint_examples = JSON.parse(IO.read( File.dirname(__FILE__) + '/../docs/endpoint_examples.json'))

    @format_endpoint = lambda do |endpoint,  request |
      action = endpoint[:method].to_s
      uri = endpoint[:uri].gsub(":id", "1") 
      results = "\n```shell\n" 
      if action == 'post'         
        results << "curl -H \"X-ArchivesSpace-Session: $SESSION\" \ \n -d #{request} \ \n 'http://localhost:8089#{uri}'"
      elsif action == 'get' 
        if endpoint[:paginated] 
          results << "curl -H \"X-ArchivesSpace-Session: $SESSION\" \ \n 'http://localhost:8089#{uri}?page=1'"
        else
          results << "curl -H \"X-ArchivesSpace-Session: $SESSION\" \ \n 'http://localhost:8089#{uri}'"
        end 
      elsif action == 'delete' 
        results << "curl -H \"X-ArchivesSpace-Session: $SESSION\" \ \n -X DELETE \n 'http://localhost:8089#{uri}'"
      end
      results << "\n```\n"
      results
    end

    erb = ERB.new(File.read('API.erb'), nil, '<>')

    File.open('../API.md', 'w') do |f|
      f.write erb.result(binding)
    end

    FileUtils.cp("../API.md", "../docs/slate/source/index.md")

    @models.each_pair do |name, klass| 
      File.open("../docs/schemas/#{name}.json", 'w') { |f| f << JSON.pretty_generate( klass.send(:schema) ) }
    end


  end
  
  desc 'Rename the YARD index file to avoid problems with Jekyll'
  task :rename_index do
    Dir.chdir('../') do
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
    Rake::Task["doc:api"].invoke
    Rake::Task["doc:yard"].invoke
    # Rake::Task["doc:yard-txt"].invoke
    Rake::Task["doc:rename_index"].invoke
  end
  
  
end
