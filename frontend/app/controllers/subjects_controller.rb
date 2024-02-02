class SubjectsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show],
                      "update_subject_record" => [:new, :edit, :create, :update, :merge],
                      "delete_subject_record" => [:delete],
                      "manage_repository" => [:defaults, :update_defaults]

  include ExportHelper


  def index
    respond_to do |format|
      format.html {
        @search_data = Search.for_type(session[:repo_id], "subject", params_for_backend_search.merge({"facet[]" => SearchResultData.SUBJECT_FACETS}))
      }
      format.csv {
        search_params = params_for_backend_search.merge({ "facet[]" => SearchResultData.SUBJECT_FACETS})
        search_params["type[]"] = "subject"
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, Search.build_filters(search_params), "#{t('subject._plural').downcase}." )
      }
    end
  end

  def current_record
    @subject
  end

  def show
    @subject = JSONModel(:subject).find(params[:id])
  end

  def new
    @subject = JSONModel(:subject).new({:vocab_id => JSONModel(:vocabulary).id_for(current_vocabulary["uri"]), :terms => [{}]})._always_valid!

    if params[:term_type]
      @subject["terms"]= [JSONModel(:term).new({:term_type => params[:term_type]})]
    end

    if user_prefs['default_values']
      defaults = DefaultValues.get 'subject'

      @subject.update(defaults.values) if defaults
    end

    render_aspace_partial :partial => "subjects/new" if inline?
  end

  def edit
    @subject = JSONModel(:subject).find(params[:id])
  end

  def create
    handle_crud(:instance => :subject,
                :model => JSONModel(:subject),
                :on_invalid => ->() {
                  return render_aspace_partial :partial => "subjects/new" if inline?
                  return render :action => :new
                },
                :on_valid => ->(id) {
                  if inline?
                    render :json => @subject.to_hash if inline?
                  else
                    flash[:success] = t("subject._frontend.messages.created")

                    if @subject["is_slug_auto"] == false &&
                       @subject["slug"] == nil &&
                       params["subject"] &&
                       params["subject"]["is_slug_auto"] == "1"

                      flash[:warning] = t("slug.autogen_disabled")
                    end

                    return redirect_to :controller => :subjects, :action => :new if params.has_key?(:plus_one)
                    redirect_to :controller => :subjects, :action => :edit, :id => id
                  end
                })
  end

  def update
    handle_crud(:instance => :subject,
                :model => JSONModel(:subject),
                :obj => JSONModel(:subject).find(params[:id]),
                :on_invalid => ->() { return render :action => :edit },
                :on_valid => ->(id) {
                  flash[:success] = t("subject._frontend.messages.updated")

                  if @subject["is_slug_auto"] == false &&
                     @subject["slug"] == nil &&
                     params["subject"] &&
                     params["subject"]["is_slug_auto"] == "1"

                    flash[:warning] = t("slug.autogen_disabled")
                  end

                  redirect_to :controller => :subjects, :action => :edit, :id => id
                })
  end

  def defaults
    defaults = DefaultValues.get 'subject'

    values = defaults ? defaults.form_values : {:vocab_id => JSONModel(:vocabulary).id_for(current_vocabulary["uri"]), :terms => [{}]}

    @subject = JSONModel(:subject).new(values)._always_valid!

    render "defaults"
  end

  def update_defaults
    begin
      DefaultValues.from_hash({
                                "record_type" => "subject",
                                "lock_version" => params[:subject].delete('lock_version'),
                                "defaults" => cleanup_params_for_schema(
                                                                        params[:subject],
                                                                        JSONModel(:subject).schema)
                              }).save

      flash[:success] = t("default_values.messages.defaults_updated")
      redirect_to :controller => :subjects, :action => :defaults
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :controller => :subjects, :action => :defaults
    end
  end


  def terms_complete
    query = "#{params[:query]}".strip

    if !query.empty?
      begin
        results = JSONModel::HTTP::get_json("/terms", :q => params[:query])['results']

        return render :json => results.map {|term|
          term["_translated"] = {}
          term["_translated"]["term_type"] = t("enumerations.subject_term_type.#{term["term_type"]}")
          term
        }
      rescue
      end
    end

    render :json => []
  end


  def merge
    handle_merge( params[:refs],
                  JSONModel(:subject).uri_for(params[:id]),
                  'subject')
  end


  def delete
    subject = JSONModel(:subject).find(params[:id])
    begin
      subject.delete
    rescue ConflictException => e
      flash[:error] = t("subject._frontend.messages.delete_conflict", :error => t("errors.#{e.conflicts}", :default => e.message))
      return redirect_to(:controller => :subjects, :action => :show, :id => subject.id)
    end

    flash[:success] = t("subject._frontend.messages.deleted")
    redirect_to(:controller => :subjects, :action => :index, :deleted_uri => subject.uri)
  end


end
