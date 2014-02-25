require_relative 'utils'

Sequel.migration do

  up do
    self[:accession].update(:system_mtime => Time.now)
  end


  down do
  end

end

