module RepositoryHelperMethods

  def login(user, pass)
    $driver.navigate.to $frontend
    $driver.wait_for_ajax
    $driver.find_element(:link, "Sign In").click
    $driver.clear_and_send_keys([:id, 'user_username'], user)
    $driver.clear_and_send_keys([:id, 'user_password'], pass)
    $driver.find_element(:id, 'login').click
    $driver.wait_for_ajax
  end


  def logout
    $driver.navigate.to $frontend
    ## Complete the logout process
    user_menu = $driver.find_elements(:css, '.user-container .dropdown-menu.pull-right').first
    if !user_menu || !user_menu.displayed?
      $driver.find_element(:css, 'body').find_element_orig(:css, '.user-container .btn.dropdown-toggle').click
    end

    $driver.find_element(:link, "Logout").click
    $driver.find_element(:link, "Sign In")
  end

  def create_test_repo(code, name, wait = true)
    create_repo = URI("#{$backend}/repositories")

    req = Net::HTTP::Post.new(create_repo.path)
    req['Content-Type'] = 'text/json'
    req.body = "{\"repo_code\": \"#{code}\", \"name\": \"#{name}\"}"

    response = admin_backend_request(req)
    repo_uri = JSON.parse(response.body)['uri']


    # Give the notification time to fire
    sleep 5 if wait

    @test_repositories ||= {}
    @test_repositories[code] = repo_uri

    [code, repo_uri]
  end


  def select_repo(code)
    code = code.respond_to?(:repo_code) ? code.repo_code : code

    $driver.find_element(:link, 'Select Repository').click
    $driver.find_element(:css, '.select-a-repository').find_element(:id => "id").select_option_with_text(code)
    $driver.click_and_wait_until_gone(:css, '.select-a-repository .btn-primary')

    if block_given?
      $test_repo_old = $test_repo
      $test_repo_uri_old = $test_repo_uri

      $test_repo = code
      $test_repo_uri = @test_repositories[code]
      yield

      $test_repo = $test_repo_old
      $test_repo_uri = $test_repo_uri_old
    end

    $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /is now active/)
  end


  def login_to_repo(user, pass, repo)
    $driver.attempt(5) {|attempt|
      begin
        logout
        $driver.wait_for_ajax
      rescue # maybe we were already logged out
      end

      login(user, pass)
      select_repo(repo)
    }
  end


  def generate_4part_id
    Digest::MD5.hexdigest("#{Time.now}#{SecureRandom.uuid}#{$$}").scan(/.{6}/)[0...1]
  end
end
