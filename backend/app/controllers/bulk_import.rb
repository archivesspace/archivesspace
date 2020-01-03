class ArchivesSpaceService < Sinatra::Base

    #Supports bulk import of spreadsheets
    Endpoint.post('/bulkimport/ssload')
        .description("Bulk Import an Excel Spreadsheet")
        .params(["repo_id", :repo_id],
                ["rid", :id],
                ["ref_id", String, "Ref ID"],
                ["position", String, "Position in tree"],
                ["type", String, "resource or archival_object"],
                ["aoid", String, "archival object ID"],
                ["filename", String, "the original file name"],
                ["filepath", String, "the spreadsheet temp path"])
        .permissions([:update_resource_record])
        .returns([200,"HTML"],
                [400, :error]) \
    do
        #right now, just return something!
        erb :'bulk/bulk_import_response'
    end

end
