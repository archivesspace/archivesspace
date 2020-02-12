require_relative 'utils'

Sequel.migration do

  up do
    $stderr.puts("Updating Resource, Accession, and Collection management tables")
    $stderr.puts("This may take a while...")
    [:resource, :accession, :collection_management].each do |table|
      self[table].update(:system_mtime => Time.now)
    end
  end


  down do
  end

end
