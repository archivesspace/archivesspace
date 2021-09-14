module ASpaceHelpers
  include Capybara::DSL

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
  end

  def select_repository(repo)
    click_link "Select Repository"
    select repo.repo_code, from: "id"
    click_button "Select Repository"
  end
end
