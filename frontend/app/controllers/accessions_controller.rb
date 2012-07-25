class AccessionsController < ApplicationController

  def index
    @accessions = Accession.all(session[:repo])
  end

  def show
    @accession = Accession.find(session[:repo], params[:id])
  end

  def new
    @accession = Accession.new({:accession_date => Date.today.strftime('%Y-%m-%d')})
  end

  def edit
    @accession = Accession.find(session[:repo], params[:id])
  end

  def create
    
    begin
      @accession = Accession.from_hash(params['accession'])
    rescue JSONModel::JSONValidationException => e
      @accession = e.invalid_object
      @errors = e.errors      
      return render action: "new"      
    end

    result = @accession.save(session[:repo])

    if result[:status] === "Created"
      redirect_to :controller=>:accessions, :action=>:show, :id=>result[:id]
    else
      render action: "new", :notice=>"Update failed: #{result[:status]}"
    end
  end

  def update

    @accession = Accession.find(session[:repo],params[:id])
    
    begin
      @accession.update(params['accession'])
    rescue JSONModel::JSONValidationException => e
      @accession = e.invalid_object
      @errors = e.errors      
      return render action: "new"      
    end
    
    result = @accession.save(session[:repo])
    
    if result[:status] === "Updated"
      redirect_to :controller=>:accessions, :action=>:show, :id=>@accession.id
    else    
      render action: "edit", :notice=>"Update failed: #{result[:status]}"
    end
  end

  def destroy
    
    @accession = Accession.find(session[:repo],params[:id])
    @accession.destroy
    
    redirect_to  :controller=>:accessions, :action=>:index
  end
end
