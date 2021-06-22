require_relative 'utils'

Sequel.migration do

  up do
    self.transaction do
      # reindex all top_container records in response ANW-462 changes to long_display_string
      self[:top_container].update(:system_mtime => Time.now)
    end
  end


  down do
  end

end
