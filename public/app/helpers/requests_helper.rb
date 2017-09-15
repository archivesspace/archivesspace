module RequestsHelper

  # https://stackoverflow.com/questions/22993545/ruby-email-validation-with-regex
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i

  def pass_email_requirements?(result)
    return true unless AppConfig[:pui_email_enabled]
    return true unless repo_email_required?
    repo_has_valid_email?(result.repository_information)
  end

  def repo_email_required?
    AppConfig.fetch(:pui_request_use_repo_email, false)
  end

  def repo_has_valid_email?(repo)
    repo && repo.has_key?('email') && repo['email'] =~ VALID_EMAIL_REGEX
  end

end