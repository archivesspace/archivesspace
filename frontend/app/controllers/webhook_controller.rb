class WebhookController < ApplicationController
  def notify
    JSONModel::Webhooks::notify(JSONModel(:webhook_notification).from_hash(JSON(params[:notification])))

    render :text => "Thanks"
  end
end
