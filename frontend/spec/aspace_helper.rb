module ASpaceHelpers
  include Capybara::DSL

  def apply_session_to_controller(controller, username, password)
    session = User.login(username, password)
    User.establish_session(controller, session, username)
    controller.session[:repo_id] = JSONModel.repository
  end

  def resource_edit_url(resource)
    "#{resource.uri.sub(%r{/repositories/\d+}, '')}/edit"
  end

  def edit_resource(resource)
    visit resource_edit_url(resource)
  end

  def login_admin
    login_user(OpenStruct.new(username: 'admin', password: 'admin'))
  end

  def login_user(user)
    visit '/'

    unless page.has_css? 'form.login'
      visit 'logout'
    end

    within "form.login" do
      fill_in "username", with: user.username
      fill_in "password", with: user.password
      click_button "Sign In"
    end
  end

  def select_repository(repo)
    click_button 'Select Repository'

    if repo.respond_to? :repo_code
      select repo.repo_code, from: 'id'
    else
      select repo, from: 'id'
    end

    within "form[action='/repositories/select']" do
      click_button 'Select Repository'
    end
  end

  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 1
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end
end
