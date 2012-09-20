class AccessionsController < ApplicationController

  def index
    @accessions = Accession.all
  end

  def show
    @accession = Accession.find(params[:id], "resolve[]" => "subjects")
  end

  def new
    @accession = Accession.new({:accession_date => Date.today.strftime('%Y-%m-%d')})._always_valid!
    @accession.extents = [JSONModel(:extent).new._always_valid!]
  end

  def edit
    @accession = Accession.find(params[:id], "resolve[]" => "subjects")
  end


  def create
    handle_crud(:instance => :accession,
                :model => Accession,
                :on_invalid => ->(){ render action: "new" },
                :on_valid => ->(id){ redirect_to(:controller => :accessions,
                                                 :action => :show,
                                                 :id => id) })
  end

  def update
    handle_crud(:instance => :accession,
                :model => Accession,
                :obj => JSONModel(:accession).find(params[:id], "resolve[]" => "subjects"),
                :on_invalid => ->(){
                  return render action: "edit"
                },
                :on_valid => ->(id){
                  redirect_to :controller => :accessions, :action => :show, :id => id
                })
  end

  def destroy

    # @accession = Accession.find(params[:id])
    # @accession.destroy

    redirect_to  :controller => :accessions, :action => :index
  end
end
