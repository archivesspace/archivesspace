class CustomReportTemplatesController < ApplicationController

  set_access_control "view_repository" => [:index],
                     "manage_repository" => [:new, :create, :delete]

  def new
    @data = nil
    @custom_report_template = JSONModel(:custom_report_template).new._always_valid!
    @custom_data = JSONModel::HTTP::get_json("/reports/custom_data")
  end


  def index
    @search_data = JSONModel(:custom_report_template).all(:page => selected_page)
  end

  def create
    @data = params['custom_report_template']['data'].dup.to_unsafe_h.to_hash
    record_type = params['custom_report_template']['data']['custom_record_type']
    data = params['custom_report_template']['data'][record_type]
      .to_unsafe_h.to_hash
    data['custom_record_type'] = record_type
    params['custom_report_template']['data'] = ASUtils.to_json(data)
    handle_crud(:instance => :custom_report_template,
                :model => JSONModel(:custom_report_template),
                :on_invalid => ->(){
                  @custom_data = JSONModel::HTTP::get_json("/reports/custom_data")
                  render :action => "new"
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("custom_report_template._frontend.messages.created")
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

end
