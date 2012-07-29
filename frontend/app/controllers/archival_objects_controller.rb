class ArchivalObjectsController < ApplicationController

  def index
    #@resource = ArchivalObject.all(session[:repo])
  end

  def show
    #@resource = ArchivalObject.find(session[:repo],params[:id_0],params[:id_1],params[:id_2],params[:id_3])
  end

  def new
    @resource = ArchivalObject.new
  end

  def create
    @resource = ArchivalObject.from_hash(params['accession'])
    render action: "new"
  end

end
