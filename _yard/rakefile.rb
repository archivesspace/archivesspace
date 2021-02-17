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
