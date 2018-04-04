class ExportsController < ApplicationController

  set_access_control  "view_repository" => [:container_labels, :download_marc, :download_dc, :download_mods,
                                            :download_mets, :download_ead, :download_eac]

  include ExportHelper


  def container_labels
     download_export(
       "/repositories/#{JSONModel::repository}/resource_labels/#{params[:id]}.tsv")
   end


  def download_marc
    download_export(
      "/repositories/#{JSONModel::repository}/resources/marc21/#{params[:id]}.xml", 
      :include_unpublished_marc => params[:include_unpublished_marc]
      )
  end


  def download_dc
    download_export(
      "/repositories/#{JSONModel::repository}/digital_objects/dublin_core/#{params[:id]}.xml")
  end


  def download_mods
    download_export(
      "/repositories/#{JSONModel::repository}/digital_objects/mods/#{params[:id]}.xml")
  end



  def download_mets
    download_export(
      "/repositories/#{JSONModel::repository}/digital_objects/mets/#{params[:id]}.xml")
  end


  def download_ead

    if params[:print_pdf] == "true"
      url = "/repositories/#{JSONModel::repository}/resource_descriptions/#{params[:id]}.pdf"
    else
      url = "/repositories/#{JSONModel::repository}/resource_descriptions/#{params[:id]}.xml"
    end

    download_export(url,
                    :include_unpublished => (params[:include_unpublished] ? params[:include_unpublished] : false),
                    :print_pdf => (params[:print_pdf] ? params[:print_pdf] : false),
                    :include_daos => (params[:include_daos] ? params[:include_daos] : false),
                    :numbered_cs => (params[:numbered_cs] ? params[:numbered_cs] : false),
                    :ead3 => (params[:ead3] ? params[:ead3] : false))
  end


  def download_eac
    download_export(
      "/repositories/#{JSONModel::repository}/archival_contexts/#{params[:type].sub(/^agent_/, '').pluralize}/#{params[:id]}.xml")
  end


  private

  def download_export(request_uri, params = {})

    meta = JSONModel::HTTP::get_json("#{request_uri}/metadata")

    respond_to do |format|
      format.html {
        self.response.headers["Content-Type"] = meta['mimetype'] if meta['mimetype']
        self.response.headers["Content-Disposition"] = "attachment; filename=#{meta['filename']}"
        self.response.headers['Last-Modified'] = Time.now.ctime.to_s

        self.response_body = Enumerator.new do |y|
          xml_response(request_uri, params) do |chunk, percent|
            y << chunk if !chunk.blank?
          end
        end
      }
    end
  end

end
