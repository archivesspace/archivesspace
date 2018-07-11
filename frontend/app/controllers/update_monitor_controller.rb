class UpdateMonitorController < ApplicationController

  set_access_control  :public => [:poll]

  # Turn off CSRF checking for this endpoint since we won't send through a
  # token, and the failed check blats out the session, which we need.
  skip_before_action :verify_authenticity_token, :only => [:poll]

  def poll
    uri = params[:uri]
    lock_version = params[:lock_version].to_i

    raise AccessDeniedException.new if !session[:user]

    if uri =~ /\/repositories\/([0-9]+)/ && session[:repo_id] != $1.to_i
      render :json => {:status => "repository_changed"}
    else
      render :json => EditMediator.record(session[:user], uri, lock_version, Time.now)
    end
  end
end
