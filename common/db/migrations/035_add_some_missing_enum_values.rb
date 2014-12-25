require_relative 'utils'

Sequel.migration do

  up do

    $stderr.puts("*** ADDING SOME ENUMS")
    enum = self[:enumeration].filter(:name => 'note_index_item_type').select(:id)
    gf = self[:enumeration_value].filter(:value => 'genre_form', :enumeration_id => enum ).select(:id).all
    if gf.length == 0
      $stderr.puts("*** Genre Form to note_index_item_type  enum list")
      self[:enumeration_value].insert(:enumeration_id => enum, :value => "genre_form", :readonly => 1)
    end

   [:resource, :archival_object, :digital_object ].each do |klass|
      $stderr.puts("Triggering reindex of #{klass.to_s}")
      self[klass ].update(:system_mtime => Time.now)
   end


  end

end
