
ASpaceImporter.importer :foo do
  def self.profile
    "A test importer that takes 0 arguments"
  end
  def run
    
    # This importer contains several examples of simple imports to ASpace.
    # Imports can be implicit or explicit in identifying their relationships
    # in the data hierarchy. If implicit-style is used, records will be assumed to belong
    # under the most recently opened records.
    # 
    # 
    #               Repository
    #                   |
    #               Collection
    #                   |
    #               Archival Object 1
    #               |       \       \
    #           AO 2        AO3     AO5
    #                         \
    #                         AO4
    
    
    # Create a new Repo
    open_new :repository, {  
                  :repo_code => "#{(0...8).map{ ('a'..'z').to_a[rand(26)] }.join}", 
                  :description => "Intergalactic Employment Agency"
                  }
    # Print something reassuring if that succeeded
    puts "Saved a new repository, and its key is #{ current :repository }" if last_succeeded?
    
    # Create a new Collection
    open_new :collection, {
                  :title => "Collection, or Resource Parent #{('A'..'Z').to_a[rand(26)]} - #{('A'..'Z').to_a[rand(26)]}"
                  }
    
    # Create a new Archival Object (AO1)
    open_new :archival_object, {
                :ref_id => "#{(0...4).map{ ('a'..'z').to_a[rand(26)] }.join}", 
                :title => "AO1 - Thing(s) #{('A'..'Z').to_a[rand(26)]} - #{('A'..'Z').to_a[rand(26)]}"
                }
                
    key_for_ao1 = current :archival_object
    
    # Add a new child without opening it
    add_new :archival_object, {
                :ref_id => "#{(0...4).map{ ('a'..'z').to_a[rand(26)] }.join}", 
                :title => "AO2 - Thing(s) #{('A'..'Z').to_a[rand(26)]} - #{('A'..'Z').to_a[rand(26)]}"
                }

    # Add a second child and open it
    open_new :archival_object, {
                :ref_id => "#{(0...4).map{ ('a'..'z').to_a[rand(26)] }.join}", 
                :title => "AO3 - Thing(s) #{('A'..'Z').to_a[rand(26)]} - #{('A'..'Z').to_a[rand(26)]}"
                }  
      
    # Add a child for AO3
    add_new :archival_object, {
                :ref_id => "#{(0...4).map{ ('a'..'z').to_a[rand(26)] }.join}", 
                :title => "AO4 - Thing(s) #{('A'..'Z').to_a[rand(26)]} - #{('A'..'Z').to_a[rand(26)]}"
                }

    # Add a third child for AO1
    open :archival_object, key_for_ao1
    add_new :archival_object, {
                :ref_id => "#{(0...4).map{ ('a'..'z').to_a[rand(26)] }.join}", 
                :title => "AO5 - Thing(s) #{('A'..'Z').to_a[rand(26)]} - #{('A'..'Z').to_a[rand(26)]}"
                }


  

  end  
end


