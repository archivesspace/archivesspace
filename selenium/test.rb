require "net/http"
require "selenium-webdriver"
require "digest"


$backend = "http://localhost:4567"
$frontend = "http://localhost:3000"

def create_test_user
  user = "testuser#{Time.now.to_i}"

  Net::HTTP::post_form(URI("#{$backend}/auth/local/user/#{user}"),
                       :password => "testuser")

  user
end


class Selenium::WebDriver::Driver
  def wait_for_ajax
    while (self.execute_script("return document.readyState") != "complete" or
           not self.execute_script("return window.$ == undefined || $.active == 0"))
      sleep(0.2)
    end
  end

  alias :find_element_orig :find_element
  def find_element(*selectors)
    wait_for_ajax

    try = 0
    while true
      begin
        return find_element_orig(*selectors)
      rescue Selenium::WebDriver::Error::NoSuchElementError => e
        if try < 5
          try += 1
          sleep 0.5
        else
          raise e
        end
      end
    end
  end


  def complete_4part_id(pattern)
    accession_id = Digest::MD5.hexdigest("#{Time.now}").scan(/.{6}/)[0...4]
    accession_id.each_with_index do |elt, i|
      self.find_element(:id => sprintf(pattern, i)).send_keys elt
    end
  end

end


def login
   ## Complete the login process
   @driver.find_element(:link, "Sign In").click
   @driver.find_element(:id, 'user_username').send_keys @user
   @driver.find_element(:id, 'user_password').send_keys "testuser"
   @driver.find_element(:id, 'login').click  
end


def logout
   ## Complete the logout process
   @driver.find_element(:link, "Logout").click
   @driver.find_element(:link, "Sign In")
end


def run
  @driver.navigate.to $frontend

  login

  ## Create a test repository
  test_repo_code = "test#{Time.now.to_i}"
  test_repo_name = "A test repository - #{Time.now}"

  @driver.find_element(:css, '.repository-container .btn').click
  @driver.find_element(:link, "Create a Repository").click
  @driver.find_element(:id => "repository_repo_code").send_keys test_repo_code
  @driver.find_element(:id => "repository_description").send_keys test_repo_name
  @driver.find_element(:css => "form#new_repository input[type='submit']").click


  ## Create an accession
  @driver.find_element(:link, "Create").click
  @driver.find_element(:link, "Accession").click

  @driver.find_element(:id => "accession_title").send_keys "Accession title"

  @driver.complete_4part_id("accession_id_%d")

  @driver.find_element(:id => "accession_accession_date").send_keys "2012-01-01"
  @driver.find_element(:id => "accession_content_description").send_keys "A box containing our own universe"
  @driver.find_element(:id => "accession_condition_description").send_keys "Slightly squashed"

  @driver.find_element(:css => "form#new_accession button[type='submit']").click


  ## Edit the accession
  @driver.find_element(:link, 'Edit Accession').click

  @driver.find_element(:id => 'accession_content_description').clear
  @driver.find_element(:id => 'accession_content_description').send_keys "Here is a description of this accession."
  @driver.find_element(:id => 'accession_condition_description').clear
  @driver.find_element(:id => 'accession_condition_description').send_keys "Here we note the condition of this accession."

  # note - the form is called 'new_accession' even though this is an edit form -jj
  @driver.find_element(:css => "form#new_accession button[type='submit']").click


  # first step towards making assertions ... do we want to rspec this?
  if @driver.find_element(:xpath => '//body').text =~ /Here is a description of this accession/
    puts "saved accession successfully"
  else
    puts "accesion save failed"
  end


  ## Edit the accession but cancel
  @driver.find_element(:link, 'Edit Accession').click
  @driver.find_element(:id => 'accession_content_description').send_keys " moo"
  @driver.find_element(:link, "Cancel").click

  if @driver.find_element(:xpath => '//body').text =~ /Here is a description of this accession. moo/
    puts "failed to cancel accession edit"
  else
    puts "accesion edit cancelled successfully"
  end


  ## Create a collection
  @driver.find_element(:link, "Create").click
  @driver.find_element(:link, "Collection").click

  @driver.find_element(:id, "collection_title").send_keys "Pony Express"
  @driver.complete_4part_id("collection_id_%d")
  @driver.find_element(:css => "form#new_collection button[type='submit']").click

  @driver.find_element(:link, "Add Child").click
  @driver.find_element(:link, "Analog Object").click
  @driver.find_element(:id, "archival_object_title").clear
  @driver.find_element(:id, "archival_object_title").send_keys("Lost mail")
  @driver.find_element(:id, "archival_object_ref_id").send_keys(Digest::MD5.hexdigest("#{Time.now}"))
  @driver.find_element(:id => "createPlusOne").click

  ["January", "February", "March", "April", "May",
   "June", "July", "August", "September", "October",
   "November", "December"]. each do |month|

    # Wait for the form to be refreshed
    while @driver.find_element(:id, "archival_object_title").attribute(:value) != "New Archival Object"
      sleep 0.2
    end

    @driver.find_element(:id, "archival_object_title").clear
    @driver.find_element(:id, "archival_object_title").send_keys(month)
    @driver.find_element(:id, "archival_object_ref_id").send_keys(Digest::MD5.hexdigest("#{month}#{Time.now}"))
    @driver.find_element(:id => "createPlusOne").click
  end

  # Prompted to dismiss changes when clicking away
  @driver.find_element(:css, "a[title='December']").click
  @driver.find_element(:id, "dismissChangesButton").click

  @driver.find_element(:link, "Add Child").click
  @driver.find_element(:link, "Analog Object").click
  @driver.find_element(:id, "archival_object_title").clear
  @driver.find_element(:id, "archival_object_title").send_keys("Christmas cards")
  @driver.find_element(:id, "archival_object_ref_id").send_keys(Digest::MD5.hexdigest("#{Time.now}"))

  # TODO: This actually reveals a bug: the last edit gets lost unless I click
  # save manually first.
  @driver.find_element(:css => "form#new_archival_object button[type='submit']").click
  # @driver.find_element(:id => "save_and_finish_editing").click

  logout

end


@user = create_test_user
@driver = Selenium::WebDriver.for :firefox
run
