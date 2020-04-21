# frozen_string_literal: true
require_relative "lib/bulk_import/bulk_import_mixins"
require_relative "lib/bulk_import/top_container_linker_validator"

class ArchivesSpaceService < Sinatra::Base
  require 'pp'
  require_relative 'lib/bulk_import/bulk_importer'
  # Supports bulk import of spreadsheets
  Endpoint.post('/bulkimport/ssload')
          .description('Bulk Import an Excel Spreadsheet')
          .params(['repo_id', :repo_id],
                  ['rid', :id],
                  ['ref_id', String, 'Ref ID'],
                  ['position', String, 'Position in tree'],
                  ['type', String, 'resource or archival_object'],
                  ['aoid', String, 'archival object ID'],
                  ['filename', String, 'the original file name'],
                  ['filepath', String, 'the spreadsheet temp path'],
                  ['digital_load', String, 'whether to load digital objects']
                )
          .permissions([:update_resource_record])
          .returns([200, 'HTML'],
                   [400, :error]) do
    # right now, just return something!
    importer = BulkImporter.new(params.fetch(:filepath), params, current_user)
    report = importer.run
    digital_load = params.fetch(:digital_load)
    digital_load = digital_load.nil? || digital_load.empty? ? false : true
    erb :'bulk/bulk_import_response', locals: {report: report, digital_load: digital_load}
  end
  
  # Supports top container linking via spreadsheet
  Endpoint.post('/bulkimport/linktopcontainers')
          .description('Top Container linking from a Spreadsheet')
          .params(['repo_id', :repo_id],
                  ['rid', :id],
                  ['filename', String, 'the original file name'],
                  ['filepath', String, 'the spreadsheet temp path'],
                  ['content_type', String, 'the spreadsheet content type']
                )
          .permissions([:update_resource_record])
          .returns([200, 'HTML'],
                   [400, :error]) do
    #Validate spreadsheet
    filepath = params.fetch(:filepath)
    content_type = params.fetch(:content_type)
    rid = params.fetch(:rid)
    tclValidator = TopContainerLinkerValidator.new(filepath, content_type, params, current_user)
    report = tclValidator.validate
    erb :'bulk/top_container_linker_response', locals: {report: report}
  end
end
