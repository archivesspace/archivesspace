module RequestsHelper

  # https://stackoverflow.com/questions/22993545/ruby-email-validation-with-regex
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i

  def pass_email_requirements?(result)
    email_enabled  = AppConfig[:pui_email_enabled]
    use_repo_email = AppConfig[:pui_request_use_repo_email]
    return true unless email_enabled and use_repo_email
    repo_has_valid_email?(result.repository_information)
  end

  def repo_has_valid_email?(repo)
    repo && repo.has_key?('email') && repo['email'] =~ VALID_EMAIL_REGEX
  end

end
