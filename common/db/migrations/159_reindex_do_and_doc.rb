require_relative 'utils'

Sequel.migration do

  up do
    $stderr.puts("Trigger reindex of all digital objects and digital object components with ids")

    # Reindex all digital objects since a digital object id is always required
    self[:digital_object].update(:system_mtime => Time.now)

    # Reindex digital object components that have an optional component id
    self[:digital_object_component].exclude(component_id: nil).update(:system_mtime => Time.now)
  end


  down do
  end

end
