class RequestsController < ApplicationController

  include PrefixHelper

  # send a request
  def make_request
    @request = RequestItem.new(params)
    errs = @request.validate
    if params["comment"].present?
      errs << I18n.t('request.failed')
    end
    if errs.blank?
      flash[:notice] = I18n.t('request.submitted')

      RequestMailer.request_received_staff_email(@request).deliver
      RequestMailer.request_received_email(@request).deliver

      redirect_to params.fetch('base_url', requested_record_path)
    else
      flash[:error] = errs
      redirect_back(fallback_location: requested_record_path) and return
    end
  end

  private

  def requested_record_path
    record = JSONModel.parse_reference(request[:request_uri].to_s)
    return root_path unless record && requestable_type?(record[:type])

    repo_id = record[:repository].to_s[%r{\A/repositories/(\d+)\z}, 1].to_i
    return root_path if repo_id.zero?

    app_prefix("/repositories/#{repo_id}/#{record[:type].to_s.pluralize}/#{record[:id].to_i}")
  end

  def requestable_type?(type)
    permitted = ASUtils.wrap(AppConfig[:pui_requests_permitted_for_types]) +
                AppConfig[:pui_repos].values.flat_map { |repo| ASUtils.wrap(repo[:requests_permitted_for_types]) }

    permitted.map(&:to_s).include?(type.to_s)
  end
end
