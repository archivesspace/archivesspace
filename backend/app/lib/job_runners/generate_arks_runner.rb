class GenerateArksRunner < JobRunner
  register_for_job_type('generate_arks_job',
                        {:create_permissions => :administer_system,
                         :cancel_permissions => :administer_system})

  # FIXME: only generate ARKs whose minter says they're no longer current.
  def run
    begin
      # RESOURCES
      @job.write_output("Generating ARKs for Resources")
      @job.write_output("================================")

      count_res = 0
      Resource.any_repo.each do |r|
        begin
          if ArkName.count == 0 || ArkName.first(resource_id: r[:id]).nil?
            @job.write_output("Generating ARK for resource id: #{r[:id]}")
            ArkName.insert(:archival_object_id => nil,
                           :resource_id        => r[:id],
                           :created_by         => 'admin',
                           :last_modified_by   => 'admin',
                           :create_time        => Time.now,
                           :system_mtime       => Time.now,
                           :user_mtime         => Time.now,
                           :lock_version       => 0)
            count_res += 1
          end
        rescue => e
          @job.write_output(" -> Error generating ARK for id: #{r[:id]} => #{e.message}")
        end
      end

      if count_res == 0
        @job.write_output("No Resource ARKs were generated because all Resource records already have ARKs")
        @job.write_output("================================")
      end

      # Archival Object
      @job.write_output("Generating ARKs for Archival Objects")
      @job.write_output("================================")

      count_aos = 0
      ArchivalObject.any_repo.each do |r|
        begin
          if ArkName.count == 0 || ArkName.first(archival_object_id: r[:id]).nil?
            @job.write_output("Generating ARK for Archival Object id: #{r[:id]}")
            ArkName.insert(:archival_object_id => r[:id],
                           :resource_id        => nil,
                           :created_by         => 'admin',
                           :last_modified_by   => 'admin',
                           :create_time        => Time.now,
                           :system_mtime       => Time.now,
                           :user_mtime         => Time.now,
                           :lock_version       => 0)
            count_aos += 1
          end
        rescue => e
          @job.write_output(" -> Error generating ARK for id: #{r[:id]} => #{e.message}")
        end
      end

      if count_aos == 0
        @job.write_output("No Archival Object ARKs were generated because all Archival Object records already have ARKs")
        @job.write_output("================================")
      end

      self.success!
    rescue Exception => e
      @job.write_output(e.message)
      @job.write_output(e.backtrace)
      raise e
    end
  end
end
