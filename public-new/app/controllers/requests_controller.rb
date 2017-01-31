class RequestsController < ApplicationController

  # send a request
  def make_request
    @request = RequestItem.new(params)
    errs = @request.validate
    if errs.blank?
      flash[:notice] = (@request.to_text_array)
      redirect_to params.fetch('base_url', request[:request_uri])
    else
      flash[:error] = errs
      redirect_back(fallback_location: request[:request_uri]) and return
    end
  end
end
