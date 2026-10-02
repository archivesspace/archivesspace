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
    visit '/logout' # ensure we are logged out before trying to login
    page.has_xpath? '//input[@id="login"]'

    within "form.login" do
      fill_in "username", with: user.username
      fill_in "password", with: user.password
      click_button "Sign In"
    end

    wait_for_ajax
    expect(page).not_to have_content('Please Sign In')
  end

  def ensure_repository_access
    i = 0
    while i < 20 do
      break unless page.has_text?('You do not have access to any Repositories.', wait: 1)

      page.refresh
      i = i + 1
    end
  end

  def select_repository(repo)
    begin
      retries ||= 0
      page.refresh unless page.has_button?('Select Repository')
      click_button 'Select Repository'
      page.has_xpath? '//select[@id="id"]', wait: 25

      if repo.respond_to? :repo_code
        select repo.repo_code, from: 'id'
      else
        select repo, from: 'id'
      end
    rescue Capybara::ElementNotFound
      page.refresh
      retry if (retries += 1) < 3
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
    page.evaluate_script("typeof window.jQuery != 'undefined'") &&
      page.evaluate_script('window.jQuery !== undefined') &&
      page.evaluate_script('jQuery.active !== undefined') &&
      page.evaluate_script('jQuery.active')&.zero?
  rescue Selenium::WebDriver::Error::JavascriptError
    false
  end

  # ApplicationController#set_locale reads user_prefs['locale'] ahead of
  # I18n.default_locale, and those preferences live in the backend (Preference.init
  # seeds a GLOBAL_USER record holding AppConfig[:locale]), so setting
  # I18n.default_locale in the spec process does not change what the browser is
  # served. A user-scoped preference in the global repository outranks the seeded
  # one for the signed-in user, which is what the preferences UI writes too.
  def set_admin_locale_preference(locale)
    prefs = JSONModel::HTTP.get_json('/current_global_preferences')
    repo_id = JSONModel(:repository).id_for(prefs['global']['repository']['ref'])

    pref = if prefs['user_global']
             JSONModel(:preference).from_hash(prefs['user_global']).tap do |p|
               p.defaults = p.defaults.merge('locale' => locale.to_s)
             end
           else
             user_id = JSONModel(:user).id_for(
               JSONModel::HTTP.get_json('/users/current-user')['uri']
             )

             JSONModel(:preference).from_hash(
               'user_id' => user_id,
               'defaults' => { 'locale' => locale.to_s }
             )
           end

    pref.save(repo_id: repo_id)
  end

  def visit_in_locale(path, locale, timeout: 45)
    deadline = Time.now + timeout
    lang = nil

    visit path

    loop do
      page.refresh
      wait_for_ajax
      lang = page.evaluate_script("document.documentElement.getAttribute('lang')")
      break if lang == locale.to_s

      raise "page never rendered in #{locale} (last lang: #{lang.inspect})" if Time.now > deadline

      sleep 1
    end
  end

  def skip_if_infinite_tree_toolbar_active
    return unless page.has_css?('#infinite-tree-toolbar', wait: 1)

    skip('Resource edit view is using InfiniteTree toolbar on this branch')
  end

end
