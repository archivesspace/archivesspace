# frozen_string_literal: true
require_relative "lib/bulk_import/bulk_import_mixins"
require_relative "lib/bulk_import/top_container_linker_validator"

class ArchivesSpaceService < Sinatra::Base
  require_relative "lib/bulk_import/bulk_importer"
  # Supports bulk import of spreadsheets
  Endpoint.post("/bulkimport/ssload")
          .description("Bulk Import an Excel Spreadsheet")
          .params(["repo_id", :repo_id],
                  ["rid", :id],
                  ["ref_id", String, "Ref ID"],
                  ["position", String, "Position in tree"],
                  ["type", String, "resource or archival_object"],
                  ["aoid", String, "archival object ID"],
                  ["filename", String, "the original file name"],
                  ["filepath", String, "the spreadsheet temp path"],
                  ["digital_load", String, "whether to load digital objects"])
          .permissions([:update_resource_record])
          .returns([200, "HTML"],
                   [400, :error]) do
    # right now, just return something!
    importer = BulkImporter.new(params.fetch(:filepath), params, current_user)
    report = importer.run
    digital_load = params.fetch(:digital_load)
    digital_load = digital_load.nil? || digital_load.empty? ? false : true
    erb :'bulk/bulk_import_response', locals: { report: report, digital_load: digital_load }
  end
  
  # Supports top container linking via spreadsheet
  Endpoint.post('/bulkimport/linktopcontainers')
          .description('Top Container linking from a Spreadsheet')
          .params(['repo_id', :repo_id],
                  ['rid', :id],
                  ['filename', String, 'the original file name'],
                  ['filepath', String, 'the spreadsheet temp path'],
                  ['filetype', String, 'file content type']
                )
          .permissions([:update_resource_record])
          .returns([200, 'HTML'],
                   [400, :error]) do
    #Validate spreadsheet
    filepath = params.fetch(:filepath)
    filetype = params.fetch(:filetype)
    rid = params.fetch(:rid)
    tclValidator = TopContainerLinkerValidator.new(filepath, filetype, current_user, params)
    report = tclValidator.run
    errors = [] 
    unless report.terminal_error.nil?
      errors << report.terminal_error
    end
    #All errors are terminal for validation
    report.rows.each do |error_row|
      if (!error_row.errors.empty?)
        errors << error_row.errors.join(", ")
      end
    end
    #If it fails, return the template
    if (!errors.empty?)
      erb :'bulk/top_container_linker_response', locals: {report: report}
    else
      #Otherwise send an error so it triggers a job creation
      raise BulkImportException.new()
    end
  end
end
