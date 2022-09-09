class BatchDeleteController < ApplicationController

  set_access_control  "delete_archival_record" => [:archival_records],
                      "delete_subject_record" => [:subjects],
                      "delete_agent_record" => [:agents],
                      "delete_classification_record" => [:classifications],
                      "administer_system" => [:locations],
                      "delete_assessment_record" => [:assessments],
                      "manage_container_profile_record" => [:container_profiles]

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

  def assessments
    delete_records(params[:record_uris])
  end

  def container_profiles
    delete_records(params[:record_uris])
  end

  private

  def delete_records(uris)
    response = JSONModel::HTTP.post_form("/batch_delete",
                                         {
                                           "record_uris[]" => Array(uris)
                                         })

    if response.code === "200"
      flash[:success] = t("batch_delete.#{params[:action]}.success")
      deleted_uri_param = params[:record_uris].map {|uri| "deleted_uri[]=#{uri}"}.join("&")
      redirect_to request.referrer.include?("?") ? "#{request.referrer}&#{deleted_uri_param}" : "#{request.referrer}?#{deleted_uri_param}"
    else
      error_flash = ''

      if response.code === "403"
        begin
          errors_by_uri = parse_failures(response.body)
          error_flash = render_delete_errors(errors_by_uri)
        rescue
          # If we couldn't successfully parse the result, report a generic error.
        end
      end

      error_title = t("batch_delete.#{params[:action]}.error")
      error_flash ||= ERB::Util.html_escape(response.body)
      flash[:error] = "#{error_title}<br/>#{error_flash}".html_safe
      redirect_to request.referrer
    end
  end

  def parse_failures(response)
    # batch delete failure
    parsed = ASUtils.json_parse(response)

    Array(parsed.fetch('error', {}).fetch('failures', [])).map do |failure|
      error_json = failure['response'].first
      next unless error_json

      error = ASUtils.json_parse(error_json)['error']
      uri = failure['uri']

      [error, uri]
    end
  end

  def render_delete_errors(errors_by_uri)
    result = ''

    unless errors_by_uri.empty?
      result += '<ul>'

      errors_by_uri.each do |error, uri|
        record_link = url_for(:controller => :resolver, :action => :resolve_readonly, :uri => uri)
        result += '<li>'
        result += "<a href=\"#{record_link}\">#{ERB::Util.html_escape(uri)}</a>"
        result += ' - '
        result += ERB::Util.html_escape(t("errors.#{error}", :default => error))
        result += '</li>'
      end

      result += '</ul>'
    end

    result
  end

end
