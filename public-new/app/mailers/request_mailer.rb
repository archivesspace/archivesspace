class RequestMailer < ApplicationMailer
  def request_received_email(request)
    user_email = request.user_email

    @request = request

    mail(from: from_address(request.repo_code), 
         to: user_email,
         subject: I18n.t('request.email.subject', :title => request.title))
  end

  def request_received_staff_email(request)
    @request = request

    mail(from: from_address(request.repo_code),
         to: to_address(request.repo_code),
         subject: I18n.t('request.email.subject', :title => request.title))
  end

  private

  def from_address(repo_code)
    begin
      AppConfig[:pui_repos][repo_code.intern][:request_email]
    rescue
      AppConfig[:pui_request_email_fallback_from_address]
    end
  end

  def to_address(repo_code)
    begin
      AppConfig[:pui_repos][repo_code][:request_email]
    rescue
      AppConfig[:pui_request_email_fallback_to_address]
    end
  end
end