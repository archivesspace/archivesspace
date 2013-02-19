class ExportsController < ApplicationController
  skip_before_filter :unauthorised_access
  
  include ExportHelper
  
  
  def download_ead
    # @ead = EADFile.new(params[:id])
    # send_file @ead.file, :type => 'application/xml', :filename => "test.ead", :x_sendfile => true
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
    Rails.logger.debug("PARAMS #{params.inspect}")
    
    # Rails.logger.debug(params[:type].sub(/^agent_/, '').pluralize)
    
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