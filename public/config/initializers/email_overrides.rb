class EmailOverrides

  def self.delivering_email(mail)
    if AppConfig.has_key?('pui_email_override')
      mail.to = AppConfig['pui_email_override']
    end
  end

end

ActionMailer::Base.register_interceptor(EmailOverrides)