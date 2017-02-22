class RequestMailer < ApplicationMailer
  def request_received_email(request)
    user_email = request.user_email

    @request = request
    mail(from: from_address(request.repo_uri), to: user_email, subject: I18n.t('request.email.subject', :title => request.title))
  end

  def request_received_staff_email(request)
    @request = request
    mail(from: from_address(request.repo_uri), to: to_address(request.repo_uri), subject: I18n.t('request.email.subject', :title => request.title))
  end

  private

  def from_address(repo_uri)
    if AppConfig.has_key?(:pui_request_email_repository_addresses)
      if AppConfig[:pui_request_email_repository_addresses].has_key?(repo_uri)
        email_config = AppConfig[:pui_request_email_repository_addresses][repo_uri]
        if email_config.kind_of? String
          return email_config
        elsif email_config.kind_of? Hash
          return email_config['from'] if email_config.has_key? 'from'
        end
      end
    end

    return AppConfig[:pui_request_email_fallback_from_address]
  end

  def to_address(repo_uri)
    if AppConfig.has_key?(:pui_request_email_repository_addresses)
      if AppConfig[:pui_request_email_repository_addresses].has_key?(repo_uri)
        email_config = AppConfig[:pui_request_email_repository_addresses][repo_uri]
        if email_config.kind_of? String
          return email_config
        elsif email_config.kind_of? Hash
          return email_config['to'] if email_config.has_key? 'to'
        end
      end
    end

    return AppConfig[:pui_request_email_fallback_to_address]
  end
end