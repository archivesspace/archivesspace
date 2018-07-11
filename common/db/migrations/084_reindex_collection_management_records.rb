require_relative 'utils'

Sequel.migration do

  up do
    self.transaction do
      # reindex all collection_management now their SOLR record `id` has changed
      self[:collection_management].update(:system_mtime => Time.now)
    end
  end


  down do
  end

end
