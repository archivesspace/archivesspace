require_relative 'utils'

Sequel.migration do

  up do
    $stderr.puts("Updating Archival Object and Digital Object Component tables")
    $stderr.puts("This may take a while...")
    [:archival_object, :digital_object_component].each do |table|
      self[table].update(:system_mtime => Time.now)
    end
  end


  down do
  end

end
