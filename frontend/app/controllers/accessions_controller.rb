class AccessionsController < ApplicationController

  def index
    @accessions = Accession.all
  end

  def show
    @accession = Accession.find(params[:id], session[:repo])
  end

  def new
    @accession = Accession.new({:accession_date => Date.today.strftime('%Y-%m-%d')})
  end

  def edit
    @accession = Accession.find(params[:id], session[:repo])
  end

  def create
    @accession = Accession.from_hash(params['accession'])

    if @accession.save(session[:repo])
      redirect_to :controller=>:accessions, :action=>:show
    else
      render action: "new"
    end
  end

  def update
    @accession = Accession.find(params[:id], session[:repo])

    if @accession.save(session[:repo])
      redirect_to :controller=>:accessions, :action=>:show
    else
      render action: "edit"
    end
  end

  def destroy
    @accession = Accession.find(params[:id], session[:repo])
    @accession.destroy
    
    redirect_to  :controller=>:accessions, :action=>:index
  end
end
