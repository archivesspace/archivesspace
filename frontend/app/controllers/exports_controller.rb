class ExportsController < ApplicationController

  set_access_control "view_repository" => [:container_labels, :download_marc, :download_dc, :download_mods,
                                            :download_mets, :download_ead, :download_eac, :download_marc_auth, :container_template, :digital_object_template]
  set_access_control "create_job" => [:print_to_pdf, :resource_duplicate]

  include ExportHelper


  def container_labels
    @resource = JSONModel(:resource).find(params[:id], find_opts)
    render :layout => false
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
      "/repositories/#{JSONModel::repository}/digital_objects/mets/#{params[:id]}.xml", :dmd => params[:dmd_scheme])
  end


  def download_ead
    url = "/repositories/#{JSONModel::repository}/resource_descriptions/#{params[:id]}.xml"

    download_export(url,
                    :include_unpublished => (params[:include_unpublished] ? params[:include_unpublished] : false),
                    :include_daos => (params[:include_daos] ? params[:include_daos] : false),
                    :include_uris => (params[:include_uris] ? params[:include_uris] : false),
                    :numbered_cs => (params[:numbered_cs] ? params[:numbered_cs] : false),
                    :ead3 => (params[:ead3] ? params[:ead3] : false))
  end


  def download_eac
    download_export(
      "/repositories/#{JSONModel::repository}/archival_contexts/#{params[:type].sub(/^agent_/, '').pluralize}/#{params[:id]}.xml")
  end

  def download_marc_auth
    download_export(
      "/repositories/#{JSONModel::repository}/agents/#{params[:type].sub(/^agent_/, '').pluralize}/marc21/#{params[:id]}.xml")
  end

  def print_to_pdf
    @resource = JSONModel(:resource).find(params[:id], find_opts)
    render :layout => false
  end

  def resource_duplicate
    @resource = JSONModel(:resource).find(params[:id], find_opts)
    render :layout => false
  end

  def container_template
    uri = "/repositories/#{JSONModel::repository}/resources/#{params[:id]}/templates/top_container_creation.csv"
    csv_response(uri)
  end

  def digital_object_template
    uri = "/repositories/#{JSONModel::repository}/resources/#{params[:id]}/templates/digital_object_creation.csv"
    csv_response(uri, {}, 'digital_object_template_')
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
