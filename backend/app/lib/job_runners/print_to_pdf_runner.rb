require_relative "../../exporters/lib/exporter"
require_relative '../AS_fop'


class PrintToPDFRunner < JobRunner
  include JSONModel

  register_for_job_type('print_to_pdf_job')

  def run
    begin

      RequestContext.open( :repo_id => @job.repo_id) do
        parsed = JSONModel.parse_reference(@json.job["source"])
        resource = Resource.get_or_die(parsed[:id])
        resource_jsonmodel = Resource.to_jsonmodel(resource)

        @job.write_output("Generating PDF for #{resource_jsonmodel["title"]}  ")

        obj = URIResolver.resolve_references(resource_jsonmodel,
                                             [ "repository", "linked_agents", "subjects", "digital_objects", 'top_container', 'top_container::container_profile'])
        opts = {
          :include_unpublished => @json.job["include_unpublished"] || false,
          :include_daos => true,
          :use_numbered_c_tags => false
        }

        record = JSONModel(:resource).new(obj)

        if record['publish'] === false
          @job.write_output("-" * 50)
          @job.write_output("Warning: this resource has not been published")
          @job.write_output("-" * 50)
        end

        ead = ASpaceExport.model(:ead).from_resource(record, resource.tree(:all, mode = :sparse), opts)
        xml = ""
        ASpaceExport.stream(ead).each { |x| xml << x }
        pdf = ASFop.new(xml).to_pdf
        job_file = @job.add_file( pdf )
        @job.write_output("File generated at #{job_file[:file_path].inspect} ")
        pdf.unlink
        @job.record_modified_uris( [@json.job["source"]] )
        @job.write_output("All done. Please click refresh to view your download link.")
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
