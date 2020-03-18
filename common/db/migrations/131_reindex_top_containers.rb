require_relative 'utils'

Sequel.migration do

  up do
    $stderr.puts("Triggering a reindex of all top containers")

    self[:top_container].update(:system_mtime => Time.now)

  end


  down do
    # can't unring a bell
  end

end
