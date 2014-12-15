class SystemInfoController < ApplicationController
  
  set_access_control  "administer_system" => [ :show]

  def show 
    @app_context = params[:app_context] ? params[:app_context] : "frontend"

    if @app_context  == "backend"
     @info = JSON.load( open( URI.join(AppConfig[:backend_url], "/system/info" ),
                             "X-ArchivesSpace-Session" => Thread.current[:backend_session],
                             "Accept" => 'application/json').read ) 
    elsif @app_context == "log" 
      @info = { :logger => $stderr.class } 
    else 
      @info = ASUtils.get_diagnostics.reject { |k,v| k == :exception } 
    end 
    
  end


end
