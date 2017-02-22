class HelloWorldController < ApplicationController

  skip_before_action :unauthorised_access

  def index
    @whosaidhello = JSONModel::HTTP::get_json('/whosaidhello')
  end
   

  def new
    JSONModel::HTTP::get_json('/helloworld', :who => session[:user])
    @whosaidhello = JSONModel::HTTP::get_json('/whosaidhello')

    render :action => :index
  end

end

