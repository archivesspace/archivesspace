require_relative "../../exporters/lib/exporter"

class ContainerLabelsRunner < JobRunner
  include JSONModel
  register_for_job_type('container_labels_job')

  def run
    begin
      RequestContext.open(:repo_id => @job.repo_id) do
        parsed = JSONModel.parse_reference(@json.job["source"])
        resource = Resource.get_or_die(parsed[:id])
        obj = URIResolver.resolve_references(Resource.to_jsonmodel(resource), ['repository'])

        @job.write_output("Generating Container Labels #{obj["title"]}  ")

        labels = ASpaceExport.model(:labels).from_resource(
          JSONModel(:resource).new(obj),
          resource.tree(:all, mode = :sparse)
        )

        job_file = @job.add_file(labels.file)
        @job.write_output("File generated at #{job_file.full_file_path.inspect} ")
        self.success!
        job_file
      end
    rescue Exception => e
      @job.write_output(e.message)
      @job.write_output(e.backtrace)
      raise e
    end
  end
end
