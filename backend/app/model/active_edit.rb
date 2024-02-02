class ActiveEdit < Sequel::Model(:active_edit)

  # If we haven't seen an update from a client in this amount of time, assume
  # they've stopped editing.
  #
  # This value needs to be at least as much as the client interval plus the
  # SYNC_WITH_BACKEND_SECONDS value from the frontend.  We add a bit of a margin
  # so that we're not expiring messages immediately after receiving them.
  EXPIRE_SECONDS = 30

  def self.update_with(active_edits)
    # Add the new ones
    active_edits['active_edits'].each do |edit|
      ActiveEdit.create(:uri => edit['uri'],
                        :operator => edit['user'],
                        :timestamp => Time.parse(edit['time']))
    end

    # Expire the old ones
    ActiveEdit.where { timestamp < (Time.now - EXPIRE_SECONDS) }.delete

    # Tally up the remaining ones
    result = {}

    # Keep track of when each URI was last edited by each user
    ActiveEdit.order(:timestamp).all.each do |edit|
      result[edit.uri] ||= {:edited_by => {}}
      result[edit.uri][:edited_by][edit.operator] = edit.timestamp
    end

    # Record the current lock version for each URI
    lock_versions = lock_versions_for(result.keys)

    result.keys.each do |uri|
      result[uri][:lock_version] = lock_versions[uri]
    end

    result
  end


  def self.lock_versions_for(uris)
    record_groups = {}

    uris.each do |uri|
      parsed = JSONModel.parse_reference(uri)

      next if !parsed
      next if parsed[:type].to_s == 'repository_with_agent'

      model = Kernel.const_get(parsed[:type].to_s.camelize)

      record_groups[model] ||= {}
      record_groups[model][parsed[:id]] = uri
    end

    result = {}
    record_groups.each do |model, records|
      model.where(:id => records.keys).
            select(:id, :lock_version).all.each do |row|
        result[records[row[:id]]] = row[:lock_version]
      end
    end

    result
  end

end
