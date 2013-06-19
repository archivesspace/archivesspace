class BatchDeleteController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:archival_records, :subjects, :agents, :classifications]
  before_filter(:only => [:archival_records]) {|c| user_must_have("delete_archival_record")}
  before_filter(:only => [:subjects]) {|c| user_must_have("delete_subject_record")}
  before_filter(:only => [:agents]) {|c| user_must_have("delete_agent_record")}
  before_filter(:only => [:classifications]) {|c| user_must_have("delete_classification_record")}


  def archival_records
    delete_records(params[:record_uris])
  end

  def subjects
    delete_records(params[:record_uris])
  end

  def agents
    delete_records(params[:record_uris])
  end

  def classifications
    delete_records(params[:record_uris])
  end

  private

  def delete_records(uris)
    response = JSONModel::HTTP.post_form("/batch_delete",
                              {
                                "record_uris[]" => Array(uris)
                              })

    if response.code === "200"
      flash[:success] = I18n.t("batch_delete.#{params[:action]}.success")
      deleted_uri_param = params[:record_uris].map{|uri| "deleted_uri[]=#{uri}"}.join("&")
      redirect_to request.referrer.include?("?") ? "#{request.referrer}&#{deleted_uri_param}" : "#{request.referrer}?#{deleted_uri_param}"
    else
      flash[:error] = "#{I18n.t("batch_delete.#{params[:action]}.error")}<br/> #{ASUtils.json_parse(response.body)["error"]["failures"].map{|err| "#{err["response"]} [#{err["uri"]}]"}.join("<br/>")}".html_safe
      redirect_to request.referrer
    end
  end

end