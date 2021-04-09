require_relative 'utils'

Sequel.migration do

  up do
    self.transaction do
      $stderr.puts("Starting top container cleanup to fix ANW-1253")

      bad_rlshp = self[:top_container_link_rlshp].exclude(sub_container_id: nil).where(top_container_id: nil).all
      if bad_rlshp.count.zero?
        $stderr.puts("Good news! No corrupt top container relationship records found in DB.")
      else
        $stderr.puts("#{bad_rlshp.count} corrupt records found in DB.")
      end

      bad_rlshp.each do |r|
        instance = self[:sub_container].where(id: r[:sub_container_id]).get(:instance_id)
        ['accession', 'archival_object', 'resource'].each do |type|
          record = self[:instance].where(id: instance).get(:"#{type}_id")
          next if record.nil?

          $stderr.puts("Bad #{type} record found: #{record.inspect}")
          repo = self[:"#{type}"].where(id: record).get(:repo_id)
          new_tc = self[:top_container].where(indicator: 'Lost and found',
                                              repo_id: repo)
                                              .get(:id)

          unless !new_tc.nil?
            new_tc = self[:top_container].insert(indicator: 'Lost and found',
                                                 repo_id: repo,
                                                 json_schema_version: 1,
                                                 create_time: Time.now,
                                                 system_mtime: Time.now,
                                                 user_mtime: Time.now)

            $stderr.puts("Created new top container #{new_tc} for repository #{repo} corrupted records.")
          end

          self[:top_container_link_rlshp].where(id: r[:id]).update(top_container_id: new_tc)
          $stderr.puts("Updated top container releationship for #{type} record #{record} to point to top container #{new_tc} in repository #{repo}.")
        end
      end
    end
  end


  down do
  end

end
