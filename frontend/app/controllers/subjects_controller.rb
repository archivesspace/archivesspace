class SubjectsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update, :terms_complete, :delete]
  before_filter(:only => [:index, :show]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :edit, :create, :update]) {|c| user_must_have("update_subject_record")}
  before_filter(:only => [:delete]) {|c| user_must_have("delete_archival_record")}

  def index
    @search_data = Search.global({"sort" => "title_sort asc"}.merge(search_params.merge({"facet[]" => SearchResultData.SUBJECT_FACETS})),
                                 "subjects")
  end

  def show
    @subject = JSONModel(:subject).find(params[:id])
  end

  def new
    @subject = JSONModel(:subject).new({:vocab_id => JSONModel(:vocabulary).id_for(current_vocabulary["uri"]), :terms => [{}]})._always_valid!
    render :partial => "subjects/new" if inline?
  end

  def edit
    @subject = JSONModel(:subject).find(params[:id])
  end

  def create
    handle_crud(:instance => :subject,
                :model => JSONModel(:subject),
                :on_invalid => ->(){
                  return render :partial => "subjects/new" if inline?
                  return render :action => :new
                },
                :on_valid => ->(id){
                  if inline?
                    render :json => @subject.to_hash if inline?
                  else
                    flash[:success] = I18n.t("subject._frontend.messages.created")
                    return redirect_to :controller => :subjects, :action => :new if params.has_key?(:plus_one)
                    redirect_to :controller => :subjects, :action => :show, :id => id
                  end
                })
  end

  def update
    handle_crud(:instance => :subject,
                :model => JSONModel(:subject),
                :obj => JSONModel(:subject).find(params[:id]),
                :on_invalid => ->(){ return render :action => :edit },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("subject._frontend.messages.updated")
                  redirect_to :controller => :subjects, :action => :show, :id => id
                })
  end

  def terms_complete
    query = "#{params[:query]}".strip

    if !query.empty?
      begin
        results = JSONModel::HTTP::get_json("/terms", :q => params[:query])['results']

        return render :json => results.map{|term|
          term["_translated"] = {}
          term["_translated"]["term_type"] = I18n.t("enumerations.subject_term_type.#{term["term_type"]}")
          term
        }
      rescue
      end
    end

    render :json => []
  end

  def delete
    subject = JSONModel(:subject).find(params[:id])
    subject.delete

    flash[:success] = I18n.t("subject._frontend.messages.deleted", JSONModelI18nWrapper.new(:subject => subject))
    redirect_to(:controller => :subjects, :action => :index, :deleted_uri => subject.uri)
  end


end
