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
    visit '/'
    page.has_xpath? '//input[@id="login"]'

    within "form.login" do
      fill_in "username", with: "admin"
      fill_in "password", with: "admin"
      click_button "Sign In"
    end

    page.has_no_xpath? "//input[@id='login']"
  end

  def login_user(user)
    visit '/'
    page.has_xpath? '//input[@id="login"]'

    within "form.login" do
      fill_in "username", with: user.username
      fill_in "password", with: user.password
      click_button "Sign In"
    end

    page.has_no_xpath? "//input[@id='login']"
  end

  def select_repository(repo)
    page.has_xpath?("//a[contains(text(), 'Select Repository')]")
    click_link 'Select Repository'
    if repo.respond_to? :repo_code
      select repo.repo_code, from: 'id'
    else
      select repo, from: 'id'
    end

    click_button 'Select Repository'
  end

  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end
end
