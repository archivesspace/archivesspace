class BatchDeleteController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:archival_records]
  before_filter(:only => [:archival_records]) {|c| user_must_have("delete_archival_record")}


  def archival_records
    response = delete_records(params[:record_uris])

    if response.code === "200"
      flash[:success] = I18n.t("batch_delete.archival_objects.success")
      deleted_uri_param = params[:record_uris].map{|uri| "deleted_uri[]=#{uri}"}.join("&")
      redirect_to request.referrer.include?("?") ? "#{request.referrer}&#{deleted_uri_param}" : "#{request.referrer}?#{deleted_uri_param}"
    else
      flash[:error] = "#{I18n.t("batch_delete.archival_objects.error")}<br/> #{response.body.inspect}".html_safe
      redirect_to request.referrer
    end
  end

  private

  def delete_records(uris)
    JSONModel::HTTP.post_form("/batch_delete",
                              {
                                "record_uris[]" => Array(uris)
                              })
  end

end