class ExportsController < ApplicationController
  skip_before_filter :unauthorised_access
  
  include ExportHelper
  
  # TODO - Condense this

  def download_dc
    request_uri = "#{AppConfig[:backend_url]}/repositories/#{Thread.current[:selected_repo_id]}/digital_objects/dublin_core/#{params[:id]}.xml"

    respond_to do |format|
      format.html {
        @filename = "DC-#{Time.now}.xml"
        self.response.headers["Content-Type"] ||= 'application/xml'
        self.response.headers["Content-Disposition"] = "attachment; filename=#{@filename}"
        self.response.headers['Last-Modified'] = Time.now.ctime.to_s

        self.response_body = Enumerator.new do |y|
          xml_response(request_uri) do |chunk, percent|
            Rails.logger.debug("#{percent} complete")
            y << chunk
          end
        end  
      }
    end
  end


  
  def download_mods
    request_uri = "#{AppConfig[:backend_url]}/repositories/#{Thread.current[:selected_repo_id]}/digital_objects/mods/#{params[:id]}.xml"

    respond_to do |format|
      format.html {
        @filename = "MODS-#{Time.now}.xml"
        self.response.headers["Content-Type"] ||= 'application/xml'
        self.response.headers["Content-Disposition"] = "attachment; filename=#{@filename}"
        self.response.headers['Last-Modified'] = Time.now.ctime.to_s

        self.response_body = Enumerator.new do |y|
          xml_response(request_uri) do |chunk, percent|
            Rails.logger.debug("#{percent} complete")
            y << chunk
          end
        end  
      }
    end
  end   
    
  def download_mets
    request_uri = "#{AppConfig[:backend_url]}/repositories/#{Thread.current[:selected_repo_id]}/digital_objects/mets/#{params[:id]}.xml"

    respond_to do |format|
      format.html {
        @filename = "METS-#{Time.now}.xml"
        self.response.headers["Content-Type"] ||= 'application/xml'
        self.response.headers["Content-Disposition"] = "attachment; filename=#{@filename}"
        self.response.headers['Last-Modified'] = Time.now.ctime.to_s

        self.response_body = Enumerator.new do |y|
          xml_response(request_uri) do |chunk, percent|
            Rails.logger.debug("#{percent} complete")
            y << chunk
          end
        end  
      }
    end
  end   
  

  def download_ead
    request_uri = "#{AppConfig[:backend_url]}/repositories/#{Thread.current[:selected_repo_id]}/resource_descriptions/#{params[:id]}.xml"
    
    respond_to do |format|
      format.html {
        @filename = "EAD-#{Time.now}.xml"
        self.response.headers["Content-Type"] ||= 'application/xml'
        self.response.headers["Content-Disposition"] = "attachment; filename=#{@filename}"
        self.response.headers['Last-Modified'] = Time.now.ctime.to_s
        
        self.response_body = Enumerator.new do |y|
          xml_response(request_uri) do |chunk, percent|
            Rails.logger.debug("#{percent} complete")
            y << chunk
          end
        end  
      }
    end
  end
  
  def download_eac
    request_uri = "#{AppConfig[:backend_url]}/archival_contexts/#{params[:type].sub(/^agent_/, '').pluralize}/#{params[:id]}.xml"
    
    respond_to do |format|
      format.html {
        @filename = "EAC-#{Time.now}.xml"
        self.response.headers["Content-Type"] ||= 'application/xml'
        self.response.headers["Content-Disposition"] = "attachment; filename=#{@filename}"
        self.response.headers['Last-Modified'] = Time.now.ctime.to_s
        
        self.response_body = Enumerator.new do |y|
          xml_response(request_uri) do |chunk, percent|
            Rails.logger.debug("#{percent} complete")
            y << chunk
          end
        end  
      }
    end
  end
end
