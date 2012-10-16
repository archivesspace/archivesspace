class WebhookController < ApplicationController
  skip_before_filter :unauthorised_access, :only => [:notify]

  def notify
    JSONModel::Webhooks::notify(JSONModel(:webhook_notification).from_hash(JSON(params[:notification])))

    render :text => "Thanks"
  end
end
