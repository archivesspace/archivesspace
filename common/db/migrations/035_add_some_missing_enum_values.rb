require_relative 'utils'

Sequel.migration do

  up do

    $stderr.puts("*** ADDING SOME ENUMS")
    enum = self[:enumeration].filter(:name => 'note_index_item_type').select(:id)
    gf = self[:enumeration_value].filter(:value => 'genre_form', :enumeration_id => enum ).select(:id).all
    $stderr.puts(gf.inspect) 
    if gf.length == 0
      $stderr.puts("*** Genre Form to note_index_item_type  enum list")
      self[:enumeration_value].insert(:enumeration_id => enum, :value => "genre_form", :readonly => 1)
    end

    Resource.all.each do |resource|
      resource.adopt_children(resource) 
    end
    
    $stderr.puts("*** TRIGGERING RESOURCE REINDEX, THIS MIGHT TAKE SOME TIME TO COMPLETE.")
    Resource.all.update(:system_mtime => Time.now )

  end

end
