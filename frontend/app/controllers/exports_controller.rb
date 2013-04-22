class ExportsController < ApplicationController
  skip_before_filter :unauthorised_access
  
  include ExportHelper
    
  def download_export(request_uri, file_prefix, file_ext = 'xml') 
    
    request_uri = "#{AppConfig[:backend_url]}#{request_uri}"
    
    mime = case file_ext
           when 'tsv' then 'text/tab-separated-values'
           else 
             'application/xml'
           end
  
    respond_to do |format|
      format.html {
        @filename = "#{file_prefix}-#{Time.now}.#{file_ext}"
        self.response.headers["Content-Type"] ||= mime
        self.response.headers["Content-Disposition"] = "attachment; filename=#{@filename}"
        self.response.headers['Last-Modified'] = Time.now.ctime.to_s

        self.response_body = Enumerator.new do |y|
          xml_response(request_uri) do |chunk, percent|
            Rails.logger.debug("#{percent} complete")
            y << chunk if !chunk.blank?
          end
        end  
      }
    end
  end
  
  def container_labels
     download_export(
       "/repositories/#{Thread.current[:selected_repo_id]}/resource_labels/#{params[:id]}.tsv", "CONTAINERLABELS", 'tsv')
   end
  
  
  def download_marc
    download_export(
      "/repositories/#{Thread.current[:selected_repo_id]}/resources/marc21/#{params[:id]}.xml", "MARC21")
  end


  def download_dc
    download_export(
      "/repositories/#{Thread.current[:selected_repo_id]}/digital_objects/dublin_core/#{params[:id]}.xml", "DC")
  end

  
  def download_mods
    download_export(
      "/repositories/#{Thread.current[:selected_repo_id]}/digital_objects/mods/#{params[:id]}.xml", "MODS")
  end


    
  def download_mets
    download_export( 
      "/repositories/#{Thread.current[:selected_repo_id]}/digital_objects/mets/#{params[:id]}.xml", "METS")
  end  
  

  def download_ead
    download_export( 
      "/repositories/#{Thread.current[:selected_repo_id]}/resource_descriptions/#{params[:id]}.xml", "EAD")
  end
  
  
  def download_eac
    download_export(
      "/archival_contexts/#{params[:type].sub(/^agent_/, '').pluralize}/#{params[:id]}.xml", "EAC")
  end
end
