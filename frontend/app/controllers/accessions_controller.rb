class AccessionsController < ApplicationController
  # GET /accessions
  # GET /accessions.json
  def index
    @accessions = Accession.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @accessions }
    end
  end

  # GET /accessions/1
  # GET /accessions/1.json
  def show
    @accession = Accession.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @accession }
    end
  end

  # GET /accessions/new
  # GET /accessions/new.json
  def new
    @accession = Accession.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @accession }
    end
  end

  # GET /accessions/1/edit
  def edit
    @accession = Accession.find(params[:id])
  end

  # POST /accessions
  # POST /accessions.json
  def create
    @accession = Accession.new(params[:accession])

    respond_to do |format|
      if @accession.save
        format.html { redirect_to @accession, notice: 'Accession was successfully created.' }
        format.json { render json: @accession, status: :created, location: @accession }
      else
        format.html { render action: "new" }
        format.json { render json: @accession.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /accessions/1
  # PUT /accessions/1.json
  def update
    @accession = Accession.find(params[:id])

    respond_to do |format|
      if @accession.update_attributes(params[:accession])
        format.html { redirect_to @accession, notice: 'Accession was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @accession.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /accessions/1
  # DELETE /accessions/1.json
  def destroy
    @accession = Accession.find(params[:id])
    @accession.destroy

    respond_to do |format|
      format.html { redirect_to accessions_url }
      format.json { head :no_content }
    end
  end
end
