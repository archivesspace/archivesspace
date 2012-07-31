
ASpaceImporter.importer :foo_repo do
  def self.profile
    "Imports dummy repositories"
  end
  def run
    test_repo = {  
                "repo_id" => "#{(0...8).map{ ('a'..'z').to_a[rand(26)] }.join}", 
                "description" => "Hudson Mongogolo Ptty LTD"
                      }  
    #Good import:
    import :repository, test_repo

    #Bad Import - Good type, bad hash
    import :repository, "flub"
    
    #Bad Import - Bad type, good hash
    import :dfsdfsdfs, test_repo
    
    
  end  
end


