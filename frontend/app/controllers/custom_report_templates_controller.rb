class CustomReportTemplatesController < ApplicationController

  set_access_control "manage_custom_report_templates" => [:new, :edit, :index, :create, :update,
    :delete, :show, :copy]

  def new
    @custom_report_template = JSONModel(:custom_report_template).new._always_valid!
  end

  def edit
    @custom_report_template = JSONModel(:custom_report_template).find(params[:id])
  end

  def current_record
    @custom_report_template
  end

  def show
    @custom_report_template = JSONModel(:custom_report_template).find(params[:id])
  end

  def index
    @search_data = JSONModel(:custom_report_template).all(
      page: selected_page,
      page_size: 50,
      sort_field: params.fetch(:sort, :name),
      sort_direction: params.fetch(:direction, :asc)
    )
  end

  def copy
    handle_crud(:instance => :custom_report_template,
                :model => JSONModel(:custom_report_template),
                :obj => JSONModel(:custom_report_template).find(params[:id]).dup,
                :replace => false,
                :copy => true,
                :on_invalid => ->() {
                  render :action => :edit
                },
                :on_valid => ->(id) {
                  flash[:success] = t("custom_report_template._frontend.messages.copied")
                  return redirect_to :controller => :custom_report_templates, :action => :new if params.has_key?(:plus_one)
                  redirect_to(:controller => :custom_report_templates, :action => :edit, :id => id)
                })
  end

  def create
    fix_params
    handle_crud(:instance => :custom_report_template,
                :model => JSONModel(:custom_report_template),
                :on_invalid => ->() {
                  render :action => "new"
                },
                :on_valid => ->(id) {
                  flash[:success] = t("custom_report_template._frontend.messages.created")
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
                :on_invalid => ->() {
                  render :action => :edit
                },
                :on_valid => ->(id) {
                  flash[:success] = t("custom_report_template._frontend.messages.updated")
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
    data['fields'].each do |name, defn|
      next unless defn.is_a?(Hash) && defn["values"] && !defn['values'].is_a?(Array)
      if defn.has_key? "values"
        defn["values"] = defn["values"].gsub("\r\n", "\n").split("\n")
      end
    end
    params['custom_report_template']['data'] = ASUtils.to_json(data)
  end

end
