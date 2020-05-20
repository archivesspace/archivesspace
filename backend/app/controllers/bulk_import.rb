# frozen_string_literal: true

class ArchivesSpaceService < Sinatra::Base
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
                  ["filetype", String, "file content type"],
                  ["digital_load", String, "whether to load digital objects"])
          .permissions([:update_resource_record])
          .returns([200, "HTML"],
                   [400, :error]) do
    digital_load = (params.fetch(:digital_load) == "true")
    if digital_load
      importer = ImportDigitalObjects.new(params.fetch(:filepath), params.fetch(:filetype), current_user, params)
    else
      importer = ImportArchivalObjects.new(params.fetch(:filepath), params.fetch(:filetype), current_user, params)
    end
    report = importer.run

    erb :'bulk/bulk_import_response', locals: { report: report, digital_load: digital_load }
  end
end
