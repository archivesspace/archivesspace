class ApplicationController < ActionController::Base
  protect_from_forgery

  # Sort of hacky.  We'll have to clean this up somehow :)
  require_relative "../../../common/jsonmodel"
  include JSONModel
end
