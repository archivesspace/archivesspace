class AccessionsController < ApplicationController

  def index
    @accessions = Accession.all(session[:repo])
  end

  def show
    @accession = Accession.find(session[:repo],params[:id_0],params[:id_1],params[:id_2],params[:id_3])
  end

  def new
    @accession = Accession.new({:accession_date => Date.today.strftime('%Y-%m-%d')})
  end

  def edit
    @accession = Accession.find(session[:repo],params[:id_0],params[:id_1],params[:id_2],params[:id_3])
  end

  def create
    begin
      @accession = Accession.from_hash(params['accession'])
    rescue JSONModel::JSONValidationException => e
      @accession = e.invalid_object
      @errors = e.errors      
      render action: "new"
      return
    end

    if @accession.save(session[:repo])
      redirect_to :controller=>:accessions, :action=>:show, :id_0=>@accession.accession_id_0, :id_1=>@accession.accession_id_1, :id_2=>@accession.accession_id_2, :id_3=>@accession.accession_id_3
    else
      render action: "new"
    end
  end

  def update

    @accession = Accession.find(session[:repo],params[:id_0],params[:id_1],params[:id_2],params[:id_3])
    @accession.update(params['accession'])
    
    if @accession.save(session[:repo])
      redirect_to :controller=>:accessions, :action=>:show, :id_0=>@accession.accession_id_0, :id_1=>@accession.accession_id_1, :id_2=>@accession.accession_id_2, :id_3=>@accession.accession_id_3
    else    
      render action: "edit"
    end
  end

  def destroy
    @accession = Accession.find(session[:repo],params[:id_0],params[:id_1],params[:id_2],params[:id_3])
    @accession.destroy
    
    redirect_to  :controller=>:accessions, :action=>:index
  end
end
