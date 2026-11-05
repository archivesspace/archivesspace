module ASpaceHelpers
  include Capybara::DSL
  include TestUtils::SpecBatchCreate

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

  # Capybara resets the browser session after every JS example, so the login
  # form and the Select Repository modal would be repeated for every example.
  # This logs in once per user and repository, saves the session cookie (the
  # frontend keeps the backend session and the selected repository in it) and
  # restores it on later calls instead. A restore leaves the browser on
  # /robots.txt, so visit a page before using it.
  #
  # The restored cookie holds the permissions and preferences read at its
  # login. They are refreshed once the frontend hears of a change from the
  # backend, which can lag a change made just before the restore, so files
  # that change the user's groups or preferences use login_user instead.
  def login_user_and_select_repository(user, repo)
    key = [user.username, repo.repo_code]
    cookies = ASpaceHelpers.saved_session_cookies[key]

    visit '/robots.txt' # cookies can only be changed for the current domain
    # Unlike /logout, this keeps the backend sessions of other saved cookies alive.
    page.driver.browser.manage.delete_all_cookies

    if cookies
      cookies.each { |cookie| page.driver.browser.manage.add_cookie(cookie) }
    else
      visit '/'
      submit_login_form(user)
      select_repository(repo)
      expect(page).to have_css('.current-repository-id', exact_text: repo.repo_code)

      ASpaceHelpers.saved_session_cookies[key] =
        page.driver.browser.manage.all_cookies.map { |cookie| cookie.slice(:name, :value, :path) }
    end
  end

  def login_admin_and_select_repository(repo)
    login_user_and_select_repository(OpenStruct.new(username: 'admin', password: 'admin'), repo)
  end

  def self.saved_session_cookies
    @saved_session_cookies ||= {}
  end

  # Logging out expires the backend session that saved cookies may refer to.
  def logout
    ASpaceHelpers.saved_session_cookies.clear
    visit '/logout'
  end

  def login_user(user)
    logout # ensure we are logged out before trying to login
    submit_login_form(user)
  end

  def submit_login_form(user)
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

  # axe measures contrast through ancestors' opacity, so a fade in progress fails it.
  def wait_for_animations
    page.document.synchronize do
      running = page.evaluate_script(<<~JS)
        (window.jQuery ? jQuery.timers.length : 0) +
          document.getAnimations().filter(a => a.effect.getTiming().iterations !== Infinity).length
      JS
      raise Capybara::ExpectationNotMet, "#{running} animations running" unless running.zero?
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

end
