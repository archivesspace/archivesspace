class ClassificationTermsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show],
                      "update_classification_record" => [:new, :edit, :create, :update, :accept_children, :transfer],
                      "delete_classification_record" => [:delete],
                      "manage_repository" => [:defaults, :update_defaults]


  def new
    @classification_term = JSONModel(:classification_term).new._always_valid!
    @classification_term.parent = {'ref' => JSONModel(:classification_term).uri_for(params[:classification_term_id])} if params.has_key?(:classification_term_id)
    @classification_term.classification = {'ref' => JSONModel(:classification).uri_for(params[:classification_id])} if params.has_key?(:classification_id)

    if user_prefs['default_values']
      defaults = DefaultValues.get 'classification_term'
      @classification_term.update(defaults.values) if defaults
      @form_title = I18n.t("classification_term._singular")
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
                :on_invalid => ->(){ render_aspace_partial :partial => "new_inline" },
                :on_valid => ->(id){

                  success_message = @classification_term.parent ?
                                      I18n.t("classification_term._frontend.messages.created_with_parent", JSONModelI18nWrapper.new(:classification_term => @classification_term, :classification => @classification_term['classification']['_resolved'], :parent => @classification_term['parent']['_resolved'])) :
                                      I18n.t("classification_term._frontend.messages.created", JSONModelI18nWrapper.new(:classification_term => @classification_term, :classification => @classification_term['classification']['_resolved']))

                  if params.has_key?(:plus_one)
                    flash[:success] = success_message
                  else
                    flash.now[:success] = success_message
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
                :on_invalid => ->(){ return render_aspace_partial :partial => "edit_inline" },
                :on_valid => ->(id){
                  success_message = parent ?
                    I18n.t("classification_term._frontend.messages.updated_with_parent", JSONModelI18nWrapper.new(:classification_term => @classification_term, :classification => @classification_term['classification']['_resolved'], :parent => parent)) :
                    I18n.t("classification_term._frontend.messages.updated", JSONModelI18nWrapper.new(:classification_term => @classification_term, :classification => @classification_term['classification']['_resolved']))
                  flash.now[:success] = success_message

                  render_aspace_partial :partial => "edit_inline"
                })
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

    flash[:success] = I18n.t("classification_term._frontend.messages.deleted", JSONModelI18nWrapper.new(:classification_term => classification_term))

    resolver = Resolver.new(classification_term['classification']['ref'])
    redirect_to resolver.view_uri
  end


  def defaults
    defaults = DefaultValues.get 'classification_term'

    values = defaults ? defaults.form_values : {}

    @classification_term = JSONModel(:classification_term).new(values)._always_valid!
    @form_title = I18n.t("default_values.form_title.classification_term")

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

      flash[:success] = I18n.t("default_values.messages.defaults_updated")
      redirect_to :controller => :classification_terms, :action => :defaults
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :controller => :classification_terms, :action => :defaults
    end
  end

end
