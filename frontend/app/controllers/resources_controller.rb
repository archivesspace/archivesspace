class ResourcesController < ApplicationController

  def index
    #@resource = Resource.all(session[:repo])
  end

  def show
    #@resource = Resource.find(session[:repo],params[:id_0],params[:id_1],params[:id_2],params[:id_3])
  end

  def new
    @resource = Resource.new
  end

  def create
    @resource = Resource.from_hash(params['accession'])
    render action: "new"
  end

end
