class AccessionsController < ApplicationController

  def index
    @accessions = Accession.all
  end

  def show
    @accession = Accession.find(params[:id])
  end

  def new
    @accession = Accession.new({:accession_date => Date.today.strftime('%Y-%m-%d')})
  end

  def edit
    @accession = Accession.find(params[:id])
  end

  def create

    begin
      @accession = Accession.from_hash(params['accession'])

      if not params.has_key?(:ignorewarnings) and not @accession._warnings.empty?
         @warnings = @accession._warnings
         return render action: "new"
      end
      
      id = @accession.save
      redirect_to :controller=>:accessions, :action=>:show, :id=>id
    rescue JSONModel::ValidationException => e
      @accession = e.invalid_object
      @errors = e.errors
      return render action: "new"
    end
  end

  def update

    @accession = Accession.find(params[:id])

    begin
      @accession.update(params['accession'])
      
      if not params.has_key?(:ignorewarnings) and not @accession._warnings.empty?
         @warnings = @accession._warnings
         return render action: "edit"
      end
            
      result = @accession.save            
      redirect_to :controller=>:accessions, :action=>:show, :id=>@accession.id
    rescue JSONModel::ValidationException => e
      @accession = e.invalid_object
      @errors = e.errors
      render action: "edit", :notice=>"Update failed: #{result[:status]}"
    end
  end

  def destroy
    
    # @accession = Accession.find(params[:id])
    # @accession.destroy
    
    redirect_to  :controller=>:accessions, :action=>:index
  end
end
