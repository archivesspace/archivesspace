class TrimWhitespaceRunner < JobRunner
  register_for_job_type('trim_whitespace_job')

  def run
    begin
      modified_records = []

      RequestContext.open(:repo_id => @job.repo_id) do

        [Resource, ArchivalObject, Accession, DigitalObject, DigitalObjectComponent].each do |record_class|
          @job.write_output("Trimming whitespace from #{record_class} titles")


          count = 0
          RequestContext.open(:current_username => @job.owner.username, :repo_id => @job.repo_id) do
            record_class.this_repo.extension(:pagination).each_page(25).each do |page_ds|
              page_ds.each do |r|
                if r[:title] && (trimmed = r[:title].strip) != r[:title]
                  count += 1
                  # update through the jsonmodel to fire off callbacks, hooks etc.
                  json = record_class.to_jsonmodel(r)
                  json['title'] = trimmed
                  record_class[r.id].update_from_json(json)
                  modified_records << r.uri
                end
              end
            end
          end
          @job.write_output("#{count} records modified.")
          @job.write_output("================================")
        end
      end

      if modified_records.empty?
        @job.write_output("All done, no records modified.")
      else
        @job.write_output("All done, logging modified records.")
      end

      self.success!

      # just reuse JobCreated api for now...
      @job.record_created_uris(modified_records)
    rescue Exception => e
      @job.write_output(e.message)
      @job.write_output(e.backtrace)
      raise e
    end
  end
end
