class SystemInfoController < ApplicationController

  set_access_control "administer_system" => [ :show, :stream_log, :reload_config]
  before_action :user_needs_to_be_global_admin

  def show
    @app_context = params[:app_context] ? params[:app_context] : "frontend_info"

    if @app_context == "backend_info"
      @info = JSON.load( open( URI.join(AppConfig[:backend_url], "/system/info" ),
                              "X-ArchivesSpace-Session" => Thread.current[:backend_session],
                              "Accept" => 'application/json').read )
    elsif @app_context == "frontend_info"
      @info = ASUtils.get_diagnostics.reject { |k, v| k == :exception }
    else
      @info = nil
    end
  end

  def stream_log
    @app_context = params[:app_context] ? params[:app_context] : "frontend_log"

    if @app_context == "backend_log"
      @log = open( URI.join(AppConfig[:backend_url], "/system/log" ),
                "X-ArchivesSpace-Session" => Thread.current[:backend_session] ).read
    else
      @log = Rails.logger.backlog_and_flush
    end

    render :plain => @log
  end

end
