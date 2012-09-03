class SubjectsController < ApplicationController

  def index
    @subjects = Subject.all
  end

  def list
    @subjects = Subject.all

    if params[:q]
      @subjects = @subjects.select {|s| s.display_string.downcase.include?(params[:q].downcase)}
    end

    respond_to do |format|
      format.json {
        render :json => @subjects
      }
    end
  end

  def show
    @subject = Subject.find(params[:id])
  end

  def new
    @subject = Subject.new({:vocab_id => JSONModel(:vocabulary).id_for(session[:vocabulary]["uri"])})._always_valid!
    render :partial => "subjects/new" if inline?
  end

  def edit
    @subject = Subject.find(params[:id])
  end

  def create
    handle_crud(:instance => :subject,
                :model => Subject,
                :on_invalid => ->(){
                  return render :partial => "subjects/new" if inline?
                  return render :action => :new
                },
                :on_valid => ->(id){
                  if inline?
                    render :json => @subject.to_hash if inline?
                  else
                    redirect_to :controller => :subjects, :action => :show, :id => id
                  end
                })
  end

  def update
    handle_crud(:instance => :subject,
                :model => Subject,
                :obj => Subject.find(params[:id]),
                :on_invalid => ->(){ return render :action => :edit },
                :on_valid => ->(id){
                  flash[:success] = "Subject Saved"
                  render :action => :show
                })
  end

end
