require_relative 'utils'

Sequel.migration do

  up do
    self[:event].update(:system_mtime => Time.now)
  end


  down do
  end

end
