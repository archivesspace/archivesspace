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

  def logout
    visit('/logout')
  end

  def login(user: nil, repo: nil)
    if user
      login_user user
    else
      login_admin
    end
    if repo
      select_repository(repo)
    end
  end

  def login_admin
    login_user(OpenStruct.new(username: 'admin', password: 'admin'))
  end

  def login_user(user)
    logout
    page.has_xpath? '//input[@id="login"]'
    within "form.login" do
      fill_in "username", with: user.username
      fill_in "password", with: user.password
      click_button "Sign In"
    end
    expect(page).to have_content('Welcome to ArchivesSpace')
    sleep 1
  end

  def select_repository(repo)
    # we might get tripped up trying to select
    # a repo that has been just created...
    MemoryLeak::Resources.refresh(:repository)
    visit "/"
    click_link 'Select Repository'
    await_jquery
    find 'ul.dropdown-menu.show'
    if repo.respond_to? :repo_code
      select repo.repo_code, from: 'id'
    else
      select repo, from: 'id'
    end

    click_button 'Select Repository'
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

  def await_jquery(wait_time = Capybara.default_max_wait_time)
    wait_time.times do
      sleep 1
      break if page.evaluate_script("typeof jQuery != 'undefined' && (jQuery.active === 0)")
    end
  end
end

Capybara::Node::Element.class_eval do
  alias_method :click_orig, :click
  # click handlers seem to take their time on our free github
  # runners, so we do this stuff. The JQuery checks seem insufficient,
  # hence the sleep - we really need a better way to know the page and all its handlers
  # are ready
  def click(*keys, **options)
    begin
      Timeout.timeout(Capybara.default_max_wait_time) do
        sleep [Capybara.default_max_wait_time-1, 5].min
        break if session.evaluate_script("typeof jQuery != 'undefined' && (jQuery.active === 0)")
      end
      click_orig(*keys, **options)
      Timeout.timeout(Capybara.default_max_wait_time) do
        sleep [Capybara.default_max_wait_time-1, 5].min
        break if session.evaluate_script("typeof jQuery != 'undefined' && (jQuery.active === 0)")
      end
    rescue Exception => e
      $logger.debug(e.inspect)
      click_orig(*keys, **options)
    end
  end
end
