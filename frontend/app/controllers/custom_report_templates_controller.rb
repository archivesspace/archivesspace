class CustomReportTemplatesController < ApplicationController

  set_access_control "create_job" => [:new, :edit, :index, :create, :update,
    :delete, :show]

  def new
    @custom_report_template = JSONModel(:custom_report_template).new._always_valid!
  end

  def edit
    @custom_report_template = JSONModel(:custom_report_template).find(params[:id])
  end

  def show
    @custom_report_template = JSONModel(:custom_report_template).find(params[:id])
    render :edit
  end

  def index
    @search_data = JSONModel(:custom_report_template).all(:page => selected_page)
  end

  def create
    fix_params
    handle_crud(:instance => :custom_report_template,
                :model => JSONModel(:custom_report_template),
                :on_invalid => ->(){
                  render :action => "new"
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("custom_report_template._frontend.messages.created")
                  return redirect_to :controller => :custom_report_templates, :action => :new if params.has_key?(:plus_one)
                  redirect_to(:controller => :custom_report_templates, :action => :index)
                })
  end

  def update
    fix_params
    handle_crud(:instance => :custom_report_template,
                :model => JSONModel(:custom_report_template),
                :obj => JSONModel(:custom_report_template).find(params[:id]),
                :replace => true,
                :on_invalid => ->(){
                  render :action => :edit
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("custom_report_template._frontend.messages.updated")
                  return redirect_to :controller => :custom_report_templates, :action => :new if params.has_key?(:plus_one)
                  redirect_to(:controller => :custom_report_templates, :action => :index)
                })
  end

  def delete
    custom_report_template = JSONModel(:custom_report_template).find(params[:id])
    custom_report_template.delete

    redirect_to(:controller => :custom_report_templates, :action => :index, :deleted_uri => custom_report_template.uri)
  end

  private

  def selected_page
    [Integer(params[:page] || 1), 1].max
  end

  def fix_params
    record_type = params['custom_report_template']['data']['custom_record_type']
    data = params['custom_report_template']['data'][record_type]
      .to_unsafe_h.to_hash
    data['custom_record_type'] = record_type
    params['custom_report_template']['data'] = ASUtils.to_json(data)
  end

end
