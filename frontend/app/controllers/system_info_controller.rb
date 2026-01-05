class SystemInfoController < ApplicationController

  set_access_control "administer_system" => [ :show, :stream_log, :show_log, :reload_config]
  before_action :user_needs_to_be_global_admin

  def show
    @app_context = params[:app_context] ? params[:app_context] : "frontend_info"
    if @app_context == "backend_info"
      @info = JSONModel::HTTP.get_json("/system/info")
    else
      @info = ASUtils.get_diagnostics.reject { |k, v| k == :exception }
    end
  end

  def show_log
    @app_context = params[:app_context] ? params[:app_context] : "frontend_log"
  end

  def stream_log
    @app_context = params[:app_context] ? params[:app_context] : "frontend_log"

    if @app_context == "backend_log"
      @log = JSONModel::HTTP.get_response(URI.parse(AppConfig[:backend_url] + "/system/log")).body
    else
      @log = Rails.logger.backlog_and_flush
    end

    render :plain => @log
  end
end
