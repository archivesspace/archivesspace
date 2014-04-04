require_relative 'utils'

Sequel.migration do

  up do
    [:accession, :resource, :archival_object, :digital_object, :digital_object_component, :event].each do |table|
      self[table].update(:system_mtime => Time.now)
    end
  end


  down do
  end

end

