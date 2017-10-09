class RequestMailer < ApplicationMailer
  def request_received_email(request)
    user_email = request.user_email

    @request = request

    mail(from: email_address(@request),
         to: user_email,
         subject: I18n.t('request.email.subject', :title => request.title))
  end

  def request_received_staff_email(request)
    @request = request

    mail(from: email_address(@request),
         to: email_address(@request, :to),
         subject: I18n.t('request.email.subject', :title => request.title))
  end

  # TODO: not implemented
  # def email_pdf_finding_aid(request, recipient_email, suggested_filename, pdf_path)
  #   attachments[suggested_filename] = File.read(pdf_path)

  #   mail(from: email_address(request),
  #        to: recipient_email,
  #        subject: I18n.t('pdf_reports.your_finding_aid_pdf', :title => record_title))
  # end

  private

  def email_address(request, type = :from)
    use_repo_email = AppConfig[:pui_request_use_repo_email]
    fallback_from  = AppConfig[:pui_request_email_fallback_from_address]
    fallback_to    = AppConfig[:pui_request_email_fallback_to_address]
    begin
      use_repo_email ? request.repo_email : AppConfig[:pui_repos][request.repo_code][:request_email]
    rescue
      type == :from ? fallback_from : fallback_to
    end
  end

end
