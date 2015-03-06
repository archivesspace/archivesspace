require_relative 'utils'

Sequel.migration do

  up do
    $stderr.puts "Making location_temporary list editble"
    $stderr.puts self[:enumeration].filter(:name => 'location_temporary').update( :editable => 1 )

  end

end
