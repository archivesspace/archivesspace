
ASpaceImporter.importer :foo do
  def self.profile
    "A test importer that takes 0 arguments"
  end
  def run
    # Step 1: Create a Repo
    test_repo = {  
                "repo_id" => "#{(0...8).map{ ('a'..'z').to_a[rand(26)] }.join}", 
                "description" => "Integalactic Employment Agency"
                      }

    res = import :repository, test_repo
    repo_id = res.parsed_response['id']
    puts "REPO ID: #{repo_id}"

    # Step 2: Create a Collection (as it's called for now)
    test_coll = {
                "id_0" => "#{(0...4).map{ ('a'..'z').to_a[rand(26)] }.join}", 
                "title" => "Resource #{('A'..'Z').to_a[rand(26)]} - #{('A'..'Z').to_a[rand(26)]}"
              }
    test_coll_params = {'repo_id' => repo_id}

    res = import :collection, test_coll, test_coll_params

    coll_id = res.parsed_response['id']
    puts "COLLECTION ID: #{coll_id}"
    
    #Step 3: Create an Archival Object
    test_ao = {
              "id_0" => "#{(0...4).map{ ('a'..'z').to_a[rand(26)] }.join}",
              "title" => "Thing or Things #{('A'..'Z').to_a[rand(26)]} - #{('A'..'Z').to_a[rand(26)]}"
    }
    test_ao_params = {'repo_id' => repo_id, 'collection' => coll_id}
    
    res = import :archival_object, test_ao, test_ao_params

    ao_id = res.parsed_response['id']
    puts "OBJECT ID #{ao_id}"
    
    #Step 4: Create a nested Archival Object
    test_ao2 = {
              "id_0" => "#{(0...4).map{ ('a'..'z').to_a[rand(26)] }.join}",
              "title" => "Thing or Things #{('A'..'Z').to_a[rand(26)]} - #{('A'..'Z').to_a[rand(26)]}"
    }
    test_ao2_params = {'repo_id' => repo_id, 'collection' => coll_id, 'parent' => ao_id}
    
    res = import :archival_object, test_ao, test_ao2_params

    ao2_id = res.parsed_response['id']
    puts "OBJECT ID #{ao2_id}"   
    
  end  
end


