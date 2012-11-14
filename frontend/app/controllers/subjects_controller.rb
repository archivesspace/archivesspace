class SubjectsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :list, :new, :edit, :create, :update]
  before_filter :user_needs_to_be_a_viewer, :only => [:index, :show, :list]
  before_filter :user_needs_to_be_an_archivist, :only => [:new, :edit, :create, :update]

  def index
    @subjects = Subject.all(:page => selected_page)
  end

  def list
    @subjects = Subject.all(:page => selected_page)

    if params[:q]
      # FIXME: this filtering belongs in the backend
      @subjects = @subjects['results'].select {|s| s.display_string.downcase.include?(params[:q].downcase)}
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
    @subject = Subject.new({:vocab_id => JSONModel(:vocabulary).id_for(current_vocabulary["uri"])})._always_valid!
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
