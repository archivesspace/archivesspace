require 'net/http'


namespace :export do

  desc "Export a resource as ead"
  task :ead, :repo_id, :resource_id do |t, args|
    
    Rake::Task["import:bootstrap"].invoke

    args.with_defaults(:repo_id => 2, :resource_id=>1)
    
    url = URI("#{AppConfig[:backend_url]}/repositories/#{args[:repo_id]}/resource_descriptions/#{args[:resource_id]}.xml")
    
    req = Net::HTTP::Get.new(url.request_uri)
    
    req['X-ArchivesSpace-Session'] = Thread.current[:backend_session]

    Net::HTTP.start(url.host, url.port) do |http|
      response = http.request(req)

      if response.code =~ /^4/
        JSONModel::handle_error(JSON.parse(response.body))
      end

      puts response.body
      
    end
    
    
  end
end


namespace :import do
  
  desc "Boostrap importer code and JSONModel"
  task :bootstrap do
    
    require_relative "lib/bootstrap"
    include JSONModel
    
  end
  
  desc "Create a repository"
  task :make_repo, :repo_code do |t, args|
    
    Rake::Task["import:bootstrap"].invoke

    args.with_defaults(:repo_code => "r#{rand(10000)}")

    repo = JSONModel(:repository).from_hash("repo_code" => args[:repo_code],
                                            "name" => "A new ArchivesSpace repository")
    repo.save
    
    puts "CREATED: #{repo.uri}"
  end
  
  
  desc "List all repositories"
  task :list_repos do
        
    Rake::Task["import:bootstrap"].invoke
    
    res = JSON.parse(`curl #{AppConfig[:backend_url]}/repositories`)
    
    puts "\n\nURI\t\tCODE\t\tDESC"  
    res.each {|r| puts "#{r['uri']}\t#{r['repo_code']}\t#{r['description']}"}   
  end

  
  desc "List all archival objects in a repository"
  task :list_objects, :repo_id, :page do |t, args|

    Rake::Task["import:bootstrap"].invoke    

    args.with_defaults(:repo_id => 2, :page => 1)
    
    url = URI("#{AppConfig[:backend_url]}/repositories/#{args[:repo_id]}/archival_objects?page=#{args[:page]}")
    
    req = Net::HTTP::Get.new(url.request_uri)
    
    req['X-ArchivesSpace-Session'] = Thread.current[:backend_session]

    Net::HTTP.start(url.host, url.port) do |http|
      response = http.request(req)

      if response.code =~ /^4/
        JSONModel::handle_error(JSON.parse(response.body))
      end

      res = JSON.parse(response.body)

      puts "\n\nURI\t\t\t\t\tTITLE(s)"        
      res['results'].each {|r| puts "#{r['uri']}\t#{r['title']}"}
      
    end
  end
end