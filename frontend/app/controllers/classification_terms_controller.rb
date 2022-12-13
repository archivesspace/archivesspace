class ClassificationTermsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show],
                      "update_classification_record" => [:new, :edit, :create, :update, :accept_children],
                      "delete_classification_record" => [:delete],
                      "manage_repository" => [:defaults, :update_defaults]


  def new
    @classification_term = JSONModel(:classification_term).new._always_valid!
    @classification_term.parent = {'ref' => JSONModel(:classification_term).uri_for(params[:classification_term_id])} if params.has_key?(:classification_term_id)
    @classification_term.classification = {'ref' => JSONModel(:classification).uri_for(params[:classification_id])} if params.has_key?(:classification_id)
    @classification_term.position = params[:position]

    if user_prefs['default_values']
      defaults = DefaultValues.get 'classification_term'
      @classification_term.update(defaults.values) if defaults
      @form_title = t("classification_term._singular")
    end

    return render_aspace_partial :partial => "classification_terms/new_inline" if inline?
  end


  def edit
    @classification_term = JSONModel(:classification_term).find(params[:id], find_opts)
    render_aspace_partial :partial => "classification_terms/edit_inline" if inline?
  end


  def create
    handle_crud(:instance => :classification_term,
                :find_opts => find_opts,
                :on_invalid => ->() { render_aspace_partial :partial => "new_inline" },
                :on_valid => ->(id) {

                  success_message = @classification_term.parent ?
                                      t("classification_term._frontend.messages.created_with_parent", classification_term_title: @classification_term.title) :
                                      t("classification_term._frontend.messages.created", classification_term_title: @classification_term.title)
                  if params.has_key?(:plus_one)
                    flash[:success] = success_message
                  else
                    flash.now[:success] = success_message
                  end

                  if @classification_term["is_slug_auto"] == false &&
                      @classification_term["slug"] == nil &&
                      params["classification_term"] &&
                      params["classification_term"]["is_slug_auto"] == "1"

                    if params.has_key?(:plus_one)
                      flash[:warning] = t("slug.autogen_disabled")
                    else
                      flash.now[:warning] = t("slug.autogen_disabled")
                    end
                  end

                  render_aspace_partial :partial => "classification_terms/edit_inline"

                })
  end


  def update
    params['classification_term']['position'] = params['classification_term']['position'].to_i if params['classification_term']['position']

    @classification_term = JSONModel(:classification_term).find(params[:id], find_opts)
    parent = @classification_term['parent'] ? @classification_term['parent']['_resolved'] : false

    handle_crud(:instance => :classification_term,
                :obj => @classification_term,
                :on_invalid => ->() { return render_aspace_partial :partial => "edit_inline" },
                :on_valid => ->(id) {

                  success_message = parent ?
                    t("classification_term._frontend.messages.updated_with_parent", classification_term_title: @classification_term.title) :
                    t("classification_term._frontend.messages.updated", classification_term_title: @classification_term.title)
                  flash.now[:success] = success_message

                  if @classification_term["is_slug_auto"] == false &&
                     @classification_term["slug"] == nil &&
                     params["classification_term"] &&
                     params["classification_term"]["is_slug_auto"] == "1"

                    flash.now[:warning] = t("slug.autogen_disabled")
                  end

                  render_aspace_partial :partial => "edit_inline"
                })
  end


  def current_record
    @classification_term
  end


  def show
    if params[:inline]
      @classification_term = JSONModel(:classification_term).find(params[:id], find_opts)
      return render_aspace_partial :partial => "classification_terms/show_inline"
    end
    @classification_id = params['classification_id']
  end


  def accept_children
    handle_accept_children(JSONModel(:classification_term))
  end


  def delete
    classification_term = JSONModel(:classification_term).find(params[:id])
    classification_term.delete

    flash[:success] = t("classification_term._frontend.messages.deleted", classification_term_title: classification_term.title)

    resolver = Resolver.new(classification_term['classification']['ref'])
    redirect_to resolver.view_uri
  end


  def defaults
    defaults = DefaultValues.get 'classification_term'

    values = defaults ? defaults.form_values : {}

    @classification_term = JSONModel(:classification_term).new(values)._always_valid!
    @form_title = t("default_values.form_title.classification_term")

    render "defaults"
  end

  def update_defaults
    begin
      DefaultValues.from_hash({
                                "record_type" => "classification_term",
                                "lock_version" => params[:classification_term].delete('lock_version'),
                                "defaults" => cleanup_params_for_schema(
                                                                        params[:classification_term],
                                                                        JSONModel(:classification_term).schema)
                              }).save

      flash[:success] = t("default_values.messages.defaults_updated")
      redirect_to :controller => :classification_terms, :action => :defaults
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :controller => :classification_terms, :action => :defaults
    end
  end

end
