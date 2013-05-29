class UpdateMonitorController < ApplicationController

  skip_before_filter :unauthorised_access


  def poll
    uri = params[:uri]
    lock_version = params[:lock_version].to_i

    if uri =~ '/repositories/[0-9]+/'
      raise "Invalid URI" unless session[:repo_id] == $1
    end

    user = session[:user]

    return if !user

    render :json => EditMediator.record(user, uri, lock_version, Time.now)
  end

end
