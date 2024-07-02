class BulkUpdateRunner < JobRunner

  register_for_job_type('bulk_update_job',
                        :create_permissions => :update_resource_record)

  def run
    job = @job

    job.write_output("Starting spreadsheet bulk update job\n")

    job.job_files.each do |input_file|
      begin
        RequestContext.open(:current_username => job.owner.username,
                            :inside_bulk_update => true,
                            :repo_id => job.repo_id) do
          summary = BulkUpdater.run(input_file.full_file_path, job)

          job.write_output("\nSuccess! %d record(s) were updated" % [
                             summary[:updated]
                           ])

          ## FIXME if bug is ever fixed upstream!
          # This is a work around as Job#record_modified_uris is not exposed
          # anywhere! So instead, we use record_created_uris just to get things
          # showing up.
          job.record_created_uris(Array(summary[:updated_uris]))

          job.job_blob = ASUtils.to_json(summary)
          job.save

          job.finish!(:completed)
          self.success!
        end
      rescue BulkUpdater::BulkUpdateFailed => e
        job.write_output("\n\n!!! Errors encountered during processing !!!")
        job.write_output("\nAll changes have been reverted.\n\n")

        e.errors.each_with_index do |error, idx|
          if idx > 0
            job.write_output("\n")
          end

          # Indented lines
          formatted_errors = error.fetch(:errors).join("\n        ")

          job.write_output("Sheet name: #{error.fetch(:sheet)}")
          job.write_output("Row number: #{error.fetch(:row)}")
          job.write_output("Column: #{error.fetch(:column, 'N/A')}")
          job.write_output("JSONModel Property: #{error.fetch(:json_property, 'N/A')}")
          job.write_output("Errors: " + formatted_errors)
        end

        job.write_output("\n\nPlease correct any issues with your import spreadsheet and retry.\n")

        job.finish!(:failed)

        raise e
      rescue => e
        Log.exception(e)
        job.write_output("Unexpected failure while running job.  Error: #{e}")

        job.finish!(:failed)
        raise e
      end
    end
  end
end
