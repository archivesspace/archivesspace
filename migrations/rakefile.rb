require 'net/http'


namespace :export do

  desc "Export a resource as ead"
  task :ead, :repo_id, :resource_id do |t, args|
    
    Rake::Task["import:bootstrap"].invoke

    args.with_defaults(:repo_id => ASpaceImportConfig::DEFAULT_REPO_ID, :resource_id=>1)
    
    url = URI("#{ASpaceImportConfig::ASPACE_BASE}/repositories/#{args[:repo_id]}/resource_descriptions/#{args[:resource_id]}.xml")
    
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
                                            "description" => "A new ArchivesSpace repository")
    repo.save
    
    puts "CREATED: #{repo.uri}"
  end
  
  desc "Create a vocabulary"
  task :make_vocab, :vocab_ref, :repo_id do |t, args|
    
    Rake::Task["import:bootstrap"].invoke
    
    args.with_defaults(:vocab_ref => "v#{rand(10000)}", :repo_id => ASpaceImportConfig::DEFAULT_REPO_ID)
    
    vocab = JSONModel(:vocabulary).from_hash("ref_id" => args[:vocab_ref],
                                              "name" => rand(100000).floor.to_s(36))
    vocab.save
    puts "CREATED: #{vocab.uri}"
  end
  
  desc "List all repositories"
  task :list_repos do
        
    Rake::Task["import:bootstrap"].invoke
    
    res = JSON.parse(`curl #{ASpaceImportConfig::ASPACE_BASE}/repositories`)
    
    puts "\n\nURI\t\tCODE\t\tDESC"  
    res.each {|r| puts "#{r['uri']}\t#{r['repo_code']}\t#{r['description']}"}   
  end
  
  desc "List all vocabularies"
  task :list_vocabs do
        
    Rake::Task["import:bootstrap"].invoke
    
    res = JSON.parse(`curl #{ASpaceImportConfig::ASPACE_BASE}/vocabularies`)
  
    puts "\n\nURI\t\tREF_ID\t\tNAME"
    res.each {|r| puts "#{r['uri']}\t#{r['ref_id']}\t#{r['name']}"} 
  end
    
  desc "List all subjects in a vocabulary"
  task :list_subjects, :vocab_id do |t, args|
    
    Rake::Task["import:bootstrap"].invoke

    args.with_defaults(:vocab_id => ASpaceImportConfig::DEFAULT_VOCAB_ID)
    
    res = JSON.parse(`curl #{ASpaceImportConfig::ASPACE_BASE}/subjects`)
    
    puts "\n\nURI\t\tTERM(s)"  
    res.each {|r| o = "#{r['uri']}\t"; r['terms'].each {|t| o << "#{t['term']} "}; puts o }
  end
  
  desc "List all archival objects in a repository"
  task :list_objects, :repo_id do |t, args|

    Rake::Task["import:bootstrap"].invoke    

    args.with_defaults(:repo_id => ASpaceImportConfig::DEFAULT_REPO_ID)
    
    url = URI("#{ASpaceImportConfig::ASPACE_BASE}/repositories/#{args[:repo_id]}/archival_objects")
    
    req = Net::HTTP::Get.new(url.request_uri)
    
    req['X-ArchivesSpace-Session'] = Thread.current[:backend_session]

    Net::HTTP.start(url.host, url.port) do |http|
      response = http.request(req)

      if response.code =~ /^4/
        JSONModel::handle_error(JSON.parse(response.body))
      end

      res = JSON.parse(response.body)

      puts "\n\nURI\t\t\t\t\tTITLE(s)"  
      res.each {|r| puts "#{r['uri']}\t#{r['title']}"}
      
    end
    

  end 
    



  # desc "List things of a given type"
  # task :list, :type, :repo_id do |t, args|
  #   
  #   Rake::Task["import:bootstrap"].invoke
  #   
  #   args.with_defaults(:type => 'archival_objects', :repo_id => ASpaceImportConfig::DEFAULT_REPO_ID)
  #   
  #   res = JSON.parse(`curl #{ASpaceImportConfig::ASPACE_BASE}/repositories/#{args[:repo_id]}/#{args[:type]}`)
  #   
  #   puts "\n\nURI\t\tTITLE"  
  #   res.each {|r| puts "#{r['uri']}\t#{r['title']}"}
  # end
  
  
end