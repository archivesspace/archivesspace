require 'mail'

# ANW-1485: This background job is intended to be a proof-of-concept for later use

class MailerRunner < JobRunner
  register_for_job_type('mailer_job',
                      {:create_permissions => :administer_system,
                       :cancel_permissions => :administer_system,
                       :allow_reregister => true})


  def send_email
    current_user = User.find(:username => @job.owner.username)

    mail = Mail.new do
       from    AppConfig[:backend_request_email_fallback_from_address]
       to      current_user[:email]
       subject 'Test Email'
       body    "Test email body"
     end

    if AppConfig[:backend_email_delivery_method] == :sendmail
      mail.delivery_method :sendmail,
        location:  AppConfig[:backend_email_sendmail_settings][:location],
        arguments: AppConfig[:backend_email_sendmail_settings][:arguments]

    elsif AppConfig[:backend_email_delivery_method] = :smtp
      mail.delivery_method :sendmail,
        address:              AppConfig[:backend_email_smtp_settings][:address],
        port:                 AppConfig[:backend_email_smtp_settings][:port],
        domain:               AppConfig[:backend_email_smtp_settings][:domain],
        user_name:            AppConfig[:backend_email_smtp_settings][:user_name],
        password:             AppConfig[:backend_email_smtp_settings][:password],
        authentication:       AppConfig[:backend_email_smtp_settings][:authentication],
        enable_starttls_auto: AppConfig[:backend_email_smtp_settings][:enable_starttls_auto]
    end

    mail.deliver
  end


  def run
    send_email
  end
end
