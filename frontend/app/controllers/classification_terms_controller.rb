class ClassificationTermsController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:index, :show, :new, :edit, :create, :update, :accept_children, :transfer, :delete]
  before_filter(:only => [:index, :show]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :edit, :create, :update, :accept_children, :transfer]) {|c| user_must_have("update_classification_record")}
  before_filter(:only => [:delete]) {|c| user_must_have("delete_classification_record")}

  FIND_OPTS = {
    "resolve[]" => ["creator"]
  }

  def new
    @classification_term = JSONModel(:classification_term).new._always_valid!
    @classification_term.parent = {'ref' => JSONModel(:classification_term).uri_for(params[:classification_term_id])} if params.has_key?(:classification_term_id)
    @classification_term.classification = {'ref' => JSONModel(:classification).uri_for(params[:classification_id])} if params.has_key?(:classification_id)

    return render :partial => "classification_terms/new_inline" if inline?
  end


  def edit
    @classification_term = JSONModel(:classification_term).find(params[:id], FIND_OPTS)
    render :partial => "classification_terms/edit_inline" if inline?
  end


  def create
    handle_crud(:instance => :classification_term,
                :find_opts => FIND_OPTS,
                :on_invalid => ->(){ render :partial => "new_inline" },
                :on_valid => ->(id){

                  success_message = @classification_term.parent ?
                                      I18n.t("classification_term._frontend.messages.created_with_parent", JSONModelI18nWrapper.new(:classification_term => @classification_term, :classification => @classification_term['classification']['_resolved'], :parent => @classification_term['parent']['_resolved'])) :
                                      I18n.t("classification_term._frontend.messages.created", JSONModelI18nWrapper.new(:classification_term => @classification_term, :classification => @classification_term['classification']['_resolved']))

                  @refresh_tree_node = true

                  if params.has_key?(:plus_one)
                    flash[:success] = success_message
                  else
                    flash.now[:success] = success_message
                  end

                  render :partial => "classification_terms/edit_inline"

                })
  end


  def update
    params['classification_term']['position'] = params['classification_term']['position'].to_i if params['classification_term']['position']

    @classification_term = JSONModel(:classification_term).find(params[:id], FIND_OPTS)
    parent = @classification_term['parent'] ? @classification_term['parent']['_resolved'] : false

    handle_crud(:instance => :classification_term,
                :obj => @classification_term,
                :on_invalid => ->(){ return render :partial => "edit_inline" },
                :on_valid => ->(id){
                  success_message = parent ?
                    I18n.t("classification_term._frontend.messages.updated_with_parent", JSONModelI18nWrapper.new(:classification_term => @classification_term, :classification => @classification_term['classification']['_resolved'], :parent => parent)) :
                    I18n.t("classification_term._frontend.messages.updated", JSONModelI18nWrapper.new(:classification_term => @classification_term, :classification => @classification_term['classification']['_resolved']))
                  flash.now[:success] = success_message

                  @refresh_tree_node = true

                  render :partial => "edit_inline"
                })
  end


  def show
    @classification_id = params['classification_id']
    @classification_term = JSONModel(:classification_term).find(params[:id], FIND_OPTS)
    render :partial => "classification_terms/show_inline" if inline?
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


end
