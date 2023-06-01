require 'action_mailer'

class UserMailer < ActionMailer::Base

  class MailError < StandardError
  end

  def headers
    delivery_method = ActionMailer::Base.delivery_method
    { delivery_method: delivery_method, to: @user.email, from: AppConfig[:global_email_from_address], subject: I18n.t('user.recover_password') }
  end

  def send_reset_token(username, token)
    self.append_view_path(File.join(ASUtils.find_base_directory, 'backend', 'app', 'views'))
    @user = User.first(username: username)
    @magic_link = AppConfig[:frontend_url] + "/users/#{username}/#{token}"

    begin
      msg = mail headers do |format|
        format.html {
          render 'send_reset_token'
        }
      end
      msg.deliver
    rescue Exception => e
      Log.error("Mailing password reset link failed: #{e.inspect}")
      raise MailError.new
    end
  end
end

# move these config settings if more mailing
# actions are added
ActionMailer::Base.raise_delivery_errors = true

if ASpaceEnvironment.environment == :unit_test
  ActionMailer::Base.delivery_method = :test
elsif AppConfig.has_key?(:email_delivery_method)
  if AppConfig[:email_delivery_method] == :smtp
    ActionMailer::Base.delivery_method = :smtp
    ActionMailer::Base.smtp_settings = AppConfig[:email_smtp_settings].dup
  elsif AppConfig[:email_delivery_method] == :sendmail
    ActionMailer::Base.delivery_method = :sendmail
    ActionMailer::Base.sendmail_settings = AppConfig[:email_sendmail_settings].dup
  end
end
