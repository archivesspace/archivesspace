class BatchDeleteController < ApplicationController

  set_access_control  "delete_archival_record" => [:archival_records],
                      "delete_subject_record" => [:subjects],
                      "delete_agent_record" => [:agents],
                      "delete_classification_record" => [:classifications],
                      "administer_system" => [:locations]
  
  def locations
    delete_records(params[:record_uris])
  end

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
