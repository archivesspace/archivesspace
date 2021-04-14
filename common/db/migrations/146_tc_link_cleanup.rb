require_relative 'utils'

Sequel.migration do

  up do
    self.transaction do
      $stderr.puts("Starting top container cleanup to fix ANW-1253")

      bad_rlshp = self[:top_container_link_rlshp].exclude(sub_container_id: nil).where(top_container_id: nil).all
      if bad_rlshp.count.zero?
        $stderr.puts("Good news! No corrupt top container relationship records found.")
      else
        $stderr.puts("\n")
        $stderr.puts("==========================================")
        $stderr.puts("\n")
        $stderr.puts("#{bad_rlshp.count} corrupted top container links found due " +
                     "to a previous failed merge of linked containers into an " + 
                     "unlinked container.")
        $stderr.puts("\n")
      end

      bad_rlshp.each do |r|
        instance = self[:sub_container].where(id: r[:sub_container_id]).get(:instance_id)
        ['accession', 'archival_object', 'resource'].each do |type|
          record = self[:instance].where(id: instance).get(:"#{type}_id")
          next if record.nil?

          $stderr.puts("     Bad top container link found on #{type} #{record}")
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

            $stderr.puts("     Creating top container #{new_tc} in repository #{repo}")
          end

          self[:top_container_link_rlshp].where(id: r[:id]).update(top_container_id: new_tc)
          $stderr.puts("     Linking #{type} #{record} to top container #{new_tc} in repository #{repo}")
        end
      end
    end
    $stderr.puts("\n")
    $stderr.puts("To identify the records that need to be corrected, do a keyword " + 
                 "search for the 'Lost and Found' top container in the Manage " +
                 "Top Containers area within the application.")
    $stderr.puts("\n")
    $stderr.puts("==========================================")
    $stderr.puts("\n")
  end


  down do
  end

end
