namespace :doc do
  
  desc "Generate the documentation"
  task :yard do
    puts "Generating YARD documentation"
    system(File.join("..", "build", "run"), "doc:yardoc")
  end
  
  # desc "Generate the supplementary txt files"
  # task :yard do
  #   puts "Generating txt versions of the schemas"
  #   system(File.join("..", "build", "run"), "doc:yardoc -f txt")
  # end

  desc "Create the API.md file"
  task :api do
    require 'erb'
    require 'sinatra'
    require_relative '../common/jsonmodel.rb'
    require_relative '../backend/app/lib/rest.rb'


    class ArchivesSpaceService < Sinatra::Base
      
      def self.helpers
        nil
      end
      
      include RESTHelpers

    end
    
    @time = Time.new

    JSONModel::init

    require_relative '../backend/app/lib/export'

    Dir.glob(File.dirname(__FILE__) + '/../backend/app/controllers/*.rb') {|file| require file}

    @endpoints = ArchivesSpaceService::Endpoint.all.sort{|a,b| a[:uri] <=> b[:uri]}

    erb = ERB.new(File.read('API.erb'), nil, '<>')

    File.open('../API.md', 'w') do |f|
      f.write erb.result(binding)
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
