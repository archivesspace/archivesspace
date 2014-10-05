class ArchivalObjectsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show, :generate_sequence],
                      "update_resource_record" => [:new, :edit, :create, :update, :transfer, :rde, :add_children, :accept_children, :validate_rows],
                      "suppress_archival_record" => [:suppress, :unsuppress],
                      "delete_archival_record" => [:delete]



  def new
    @archival_object = JSONModel(:archival_object).new._always_valid!
    @archival_object.parent = {'ref' => JSONModel(:archival_object).uri_for(params[:archival_object_id])} if params.has_key?(:archival_object_id)
    @archival_object.resource = {'ref' => JSONModel(:resource).uri_for(params[:resource_id])} if params.has_key?(:resource_id)

    return render_aspace_partial :partial => "archival_objects/new_inline" if inline?

    # render the full AO form

  end

  def edit
    @archival_object = JSONModel(:archival_object).find(params[:id], find_opts)

    if @archival_object.suppressed
      return redirect_to(:action => :show, :id => params[:id], :inline => params[:inline])
    end

    render_aspace_partial :partial => "archival_objects/edit_inline" if inline?
  end


  def create
    handle_crud(:instance => :archival_object,
                :find_opts => find_opts,
                :on_invalid => ->(){ render_aspace_partial :partial => "new_inline" },
                :on_valid => ->(id){

                  success_message = @archival_object.parent ?
                                      I18n.t("archival_object._frontend.messages.created_with_parent", JSONModelI18nWrapper.new(:archival_object => @archival_object, :resource => @archival_object['resource']['_resolved'], :parent => @archival_object['parent']['_resolved'])) :
                                      I18n.t("archival_object._frontend.messages.created", JSONModelI18nWrapper.new(:archival_object => @archival_object, :resource => @archival_object['resource']['_resolved']))

                  @refresh_tree_node = true

                  if params.has_key?(:plus_one)
                    flash[:success] = success_message
                  else
                    flash.now[:success] = success_message
                  end

                  render_aspace_partial :partial => "archival_objects/edit_inline"

                })
  end


  def update
    params['archival_object']['position'] = params['archival_object']['position'].to_i if params['archival_object']['position']

    @archival_object = JSONModel(:archival_object).find(params[:id], find_opts)
    resource = @archival_object['resource']['_resolved']
    parent = @archival_object['parent'] ? @archival_object['parent']['_resolved'] : false

    handle_crud(:instance => :archival_object,
                :obj => @archival_object,
                :on_invalid => ->(){ return render_aspace_partial :partial => "edit_inline" },
                :on_valid => ->(id){
                  success_message = parent ?
                    I18n.t("archival_object._frontend.messages.updated_with_parent", JSONModelI18nWrapper.new(:archival_object => @archival_object, :resource => @archival_object['resource']['_resolved'], :parent => parent)) :
                    I18n.t("archival_object._frontend.messages.updated", JSONModelI18nWrapper.new(:archival_object => @archival_object, :resource => @archival_object['resource']['_resolved']))
                  flash.now[:success] = success_message

                  @refresh_tree_node = true

                  render_aspace_partial :partial => "edit_inline"
                })
  end


  def show
    @resource_id = params['resource_id']
    @archival_object = JSONModel(:archival_object).find(params[:id], find_opts)

    flash.now[:info] = I18n.t("archival_object._frontend.messages.suppressed_info", JSONModelI18nWrapper.new(:archival_object => @archival_object)) if @archival_object.suppressed

    render_aspace_partial :partial => "archival_objects/show_inline" if inline?
  end


  def accept_children
    handle_accept_children(JSONModel(:archival_object))
  end


  def transfer
    begin
      post_data = {
        :target_resource => params["transfer"]["ref"],
        :component => JSONModel(:archival_object).uri_for(params[:id])
      }

      response = JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/component_transfers", post_data)

      if response.code == '200'
        @archival_object = JSONModel(:archival_object).find(params[:id], find_opts)

        flash[:success] = I18n.t("archival_object._frontend.messages.transfer_success", JSONModelI18nWrapper.new(:archival_object => @archival_object, :resource => @archival_object['resource']['_resolved']))
        redirect_to :controller => :resources, :action => :edit, :id => JSONModel(:resource).id_for(params["transfer"]["ref"]), :anchor => "tree::archival_object_#{params[:id]}"
      else
        raise ASUtils.json_parse(response.body)['error'].to_s
      end

    rescue Exception => e
      flash[:error] = I18n.t("archival_object._frontend.messages.transfer_error", :exception => e)
      redirect_to :controller => :resources, :action => :edit, :id => params["transfer"]["current_resource_id"], :anchor => "tree::archival_object_#{params[:id]}"
    end
  end


  def delete
    archival_object = JSONModel(:archival_object).find(params[:id])
    archival_object.delete

    flash[:success] = I18n.t("archival_object._frontend.messages.deleted", JSONModelI18nWrapper.new(:archival_object => archival_object))

    resolver = Resolver.new(archival_object['resource']['ref'])
    redirect_to resolver.view_uri
  end


  def rde
    @parent = JSONModel(:archival_object).find(params[:id])
    @children = ArchivalObjectChildren.new
    @exceptions = []

    render_aspace_partial :partial => "shared/rde"
  end


  def add_children
    @parent = JSONModel(:archival_object).find(params[:id])

    if params[:archival_record_children].blank? or params[:archival_record_children]["children"].blank?

      @children = ArchivalObjectChildren.new
      flash.now[:error] = I18n.t("rde.messages.no_rows")

    else
      children_data = cleanup_params_for_schema(params[:archival_record_children], JSONModel(:archival_record_children).schema)

      begin
        @children = ArchivalObjectChildren.from_hash(children_data, false)

        if params["validate_only"] == "true"
          @exceptions = @children.children.collect{|c| JSONModel(:archival_object).from_hash(c, false)._exceptions}

          error_count = @exceptions.select{|e| !e.empty?}.length
          if error_count > 0
            flash.now[:error] = I18n.t("rde.messages.rows_with_errors", :count => error_count)
          else
            flash.now[:success] = I18n.t("rde.messages.rows_no_errors")
          end

          return render_aspace_partial :partial => "shared/rde"
        else
          @children.save(:archival_object_id => @parent.id)
        end

        return render :text => I18n.t("rde.messages.success")
      rescue JSONModel::ValidationException => e
        @exceptions = @children.children.collect{|c| JSONModel(:archival_object).from_hash(c, false)._exceptions}

        flash.now[:error] = I18n.t("rde.messages.rows_with_errors", :count => @exceptions.select{|e| !e.empty?}.length)
      end

    end

    render_aspace_partial :partial => "shared/rde"
  end


  def validate_rows
    row_data = cleanup_params_for_schema(params[:archival_record_children], JSONModel(:archival_record_children).schema)

    # build the AOC record but don't bother validating it yet...
    aoc = ArchivalObjectChildren.from_hash(row_data, false, true)

    # validate each row individually (to avoid weird indexes in the error paths)
    render :json => aoc.children.collect{|c| JSONModel(:archival_object).from_hash(c, false)._exceptions}
  end


  def suppress
    archival_object = JSONModel(:archival_object).find(params[:id])
    archival_object.set_suppressed(true)

    flash[:success] = I18n.t("archival_object._frontend.messages.suppressed", JSONModelI18nWrapper.new(:archival_object => archival_object))
    redirect_to(:controller => :resources, :action => :show, :id => JSONModel(:resource).id_for(archival_object['resource']['ref']), :anchor => "tree::archival_object_#{params[:id]}")
  end


  def unsuppress
    archival_object = JSONModel(:archival_object).find(params[:id])
    archival_object.set_suppressed(false)

    flash[:success] = I18n.t("archival_object._frontend.messages.unsuppressed", JSONModelI18nWrapper.new(:archival_object => archival_object))
    redirect_to(:controller => :resources, :action => :show, :id => JSONModel(:resource).id_for(archival_object['resource']['ref']), :anchor => "tree::archival_object_#{params[:id]}")
  end

end
