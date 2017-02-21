class RequestsController < ApplicationController

  # send a request
  def make_request
    @request = RequestItem.new(params)
    errs = @request.validate
    if errs.blank?
      flash[:notice] = I18n.t('request.submitted')

      RequestMailer.request_received_staff_email(@request).deliver
      RequestMailer.request_received_email(@request).deliver

      redirect_to params.fetch('base_url', request[:request_uri])
    else
      flash[:error] = errs
      redirect_back(fallback_location: request[:request_uri]) and return
    end
  end
end
