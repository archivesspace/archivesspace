class UpdateMonitorController < ApplicationController

  set_access_control  :public => [:poll]


  def poll
    uri = params[:uri]
    lock_version = params[:lock_version].to_i

    if uri =~ /\/repositories\/([0-9]+)/
      raise "Invalid URI" unless session[:repo_id] == $1.to_i
    end

    raise AccessDeniedException.new if !session[:user]

    render :json => EditMediator.record(session[:user], uri, lock_version, Time.now)
  end

end
