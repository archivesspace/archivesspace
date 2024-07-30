require_relative "../bulk_archival_object_updater"

class BulkArchivalObjectUpdaterRunner < JobRunner
  register_for_job_type('bulk_archival_object_updater_job', :create_permissions => :update_resource_record)

  def run
    @job.write_output("Starting spreadsheet bulk archival object updater job\n")

    if @job.job_files.length != 1
      @job.write_output("\nNo spreadsheet found.\n")
      @job.finish!(:failed)

      raise Exception.new('No spreadsheet found.')
    end

    spreadsheet = @job.job_files[0]

    begin
      RequestContext.open(:current_username => @job.owner.username,
                          :inside_bulk_update => true,
                          :repo_id => @job.repo_id) do

        parameters = {}
        if @job.job.has_key?('create_missing_top_containers')
          parameters['create_missing_top_containers'] = @job.job['create_missing_top_containers']
        end

        bulk_archival_object_updater = BulkArchivalObjectUpdater.new(spreadsheet.full_file_path, parameters.transform_keys(&:to_sym))

        result = bulk_archival_object_updater.run

        bulk_archival_object_updater.info_messages.each do |message|
          @job.write_output(message)
        end

        @job.write_output("\nBulk update job successfully completed. %d record(s) were updated." % [ result[:updated_uris].length ])
        @job.record_created_uris(result[:updated_uris])
        @job.job_blob = ASUtils.to_json(result)
        @job.job_files[0].delete
        @job.save
        @job.finish!(:completed)
        self.success!
      end
    rescue BulkArchivalObjectUpdater::BulkUpdateFailed => e
      @job.write_output("\nErrors encountered during processing.\n")
      @job.write_output("All changes have been reverted.\n\n")

      e.errors.each_with_index do |error, index|
        if index > 0
          @job.write_output("\n")
        end

        formatted_errors = error.fetch(:errors).join("\n")

        @job.write_output("Sheet name: #{error.fetch(:sheet)}")
        @job.write_output("Row number: #{error.fetch(:row)}")
        @job.write_output("Column: #{error.fetch(:column, 'N/A')}")
        @job.write_output("JSONModel Property: #{error.fetch(:json_property, 'N/A')}")
        @job.write_output("Errors: " + formatted_errors)
      end

      @job.write_output("\nPlease correct any issues with your import spreadsheet and retry.\n")
      @job.finish!(:failed)

      raise e
    rescue => e
      Log.exception(e)
      @job.write_output("Unexpected failure while running @job. Error: #{e}")

      @job.finish!(:failed)
      raise e
    end
  end
end
