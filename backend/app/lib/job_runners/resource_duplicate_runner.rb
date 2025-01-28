require_relative "../resource/duplicate"

class ResourceDuplicateRunner < JobRunner
  include JSONModel

  register_for_job_type('resource_duplicate_job', :hidden => true)

  def run
    begin
      RequestContext.open( :repo_id => @job.repo_id) do
        parsed = JSONModel.parse_reference(@json.job["source"])
        resource_id = parsed[:id]

        @job.write_output(I18n.t("resource_duplicate_job.going_to_duplicate_job", resource_id: resource_id))

        resource_duplicate = ::Lib::Resource::Duplicate.new(resource_id)
        resource_duplicate.duplicate

        if resource_duplicate.errors.length == 0
          @job.write_output(I18n.t("resource_duplicate_job.success_message", resource_source_id: resource_id, resource_duplicated_id: resource_duplicate.resource.id))
          @job.write_output(I18n.t('resource_duplicate_job.success_reload_message'))

          @job.record_created_uris([resource_duplicate.resource.uri])

          return
        end

        resource_duplicate.errors.each do |error|
          @job.write_output(error[:error])
        end
      end
    rescue Exception => e
      @job.write_output(e.message)
      @job.write_output(e.backtrace)
      raise e
    end

    @job.write_output(I18n.t('resource_duplicate_job.job_failed'))
    raise 'Job Failed'
  end
end
