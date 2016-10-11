class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/plugins/public_formats/repository/:repo_id/:type/:format/:id.xml')
    .description("Get an archival object by format without permissions")
    .params(["repo_id", :repo_id],
            ["type", String, "The type of object, resource or digital_object"],
            ["format", String, "The format to return the object as"],
            ["id", :id])
    .permissions([:view_repository])
    .returns([200, "Archival Object"]) \
  do
    handle params[:format], params[:id]
  end

  Endpoint.get('/plugins/public_formats/repository/:repo_id/:type/:format/:id.pdf')
    .description("Get an archival object edf-pdf  without permissions")
    .params(["repo_id", :repo_id],
            ["type", String, "The type of object, resource or digital_object"],
            ["format", String, "The format to return the object as"],
            ["id", :id])
    .permissions([:view_repository])
    .returns([200, "Archival Object"]) \
  do
    handle "#{params[:format]}_pdf", params[:id]
  end


  # html requires the ead
  def format_tree
    {
      ead: [:stream_response, :generate_ead, true, false, false],
      html: [:stream_response, :generate_ead, true, false, false],
      marcxml: [:xml_response, :generate_marc],
      dc: [:xml_response, :generate_dc],
      mets: [:xml_response, :generate_mets],
      mods: [:xml_response, :generate_mods],
      pdf: [ :pdf_response ] 
    }
  end

  def handle(format_mime, id)
    format, mime = format_mime.split("_") 
    responder, generater, *args = format_tree[format.intern]
    
    if mime and mime.intern == :pdf
      data_source = args.any? ? self.send( "generate_#{format}", id, *args) :  self.send("generate_#{format}", id)
      data = args.any? ? self.send( "generate_pdf_from_#{format}", data_source) :  self.send("generate_#{format}", id)
    else 
      data = args.any? ? self.send(generater, id, *args) :  self.send(generater, id)
    end
    
    self.send(responder, data)    
  end

end
