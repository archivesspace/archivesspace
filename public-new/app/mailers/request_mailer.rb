class RequestMailer < ApplicationMailer
  default from: AppConfig[:pui_request_email_from_address]

  def request_received_email(request)
    user_email = request.user_email

    @request = request
    mail(to: user_email, subject: I18n.t('request.email.subject', :title => request.title))
  end

  def request_received_staff_email(request)
    @request = request
    mail(to: AppConfig[:pui_request_email_staff_address], subject: I18n.t('request.email.subject', :title => request.title))
  end

end