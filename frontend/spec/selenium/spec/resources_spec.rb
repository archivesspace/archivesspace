require_relative 'spec_helper'

describe "Resources Form" do

  before(:all) do
    @repo = create(:repo, :repo_code => "resources_test_#{Time.now.to_i}")

    create_subjects
    set_repo @repo
    run_all_indexers


    @viewer_user = create_user(@repo => ['repository-viewers'])

    @driver = Driver.get
    @driver.login_to_repo($admin, @repo)
  end

  before(:each) do
    @r = create(:resource)

    @driver.get_edit_page(@r)
    @driver.wait_for_ajax
  end


  after(:all) do
    @driver.quit
  end


  describe "search dropdown" do
    it "displays correct icon for cultural_context term_type in search dropdown" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click
      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  cultural_context")
  
      @driver.find_element(:css, ".subject_type_cultural_context")
    end
  
    it "displays correct icon for function term_type in search dropdown"   do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click
      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  function")
  
      @driver.find_element(:css, ".subject_type_function")
    end
  
    it "displays correct icon for genre_form term_type in search dropdown  " do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click
      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  genre_form")
  
      @driver.find_element(:css, ".subject_type_genre_form")
    end
  
    it "displays correct icon for technique term_type in search dropdown  " do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click
      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "technique")

      @driver.find_element(:css, ".subject_type_technique")
    end
  
    it "displays correct icon for occupation term_type in search dropdown" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click
      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "occupation")
  
      @driver.find_element(:css, ".subject_type_occupation")
    end
  
    it "displays correct icon for style_period term_type in search dropdown" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click
      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "style_period")
  
      @driver.find_element(:css, ".subject_type_style_period")
    end
  
    it "displays correct icon for technique term_type in search dropdown" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click
      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "technique")
  
      @driver.find_element(:css, ".subject_type_technique")
    end
  
    it "displays correct icon for temporal term_type in search dropdown" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click
      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "temporal")
  
      @driver.find_element(:css, ".subject_type_temporal")
    end
  
    it "displays correct icon for topical term_type in search dropdown" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click
      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "topical")
  
      @driver.find_element(:css, ".subject_type_topical")
    end
  
    it "displays correct icon for uniform_title term_type in search dropdown" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click
      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "uniform_title")
  
      @driver.find_element(:css, ".subject_type_uniform_title")
    end
  end

  describe "subject selection" do
    it "displays correct icon for cultural_context term_type in subject selection" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  cultural_context")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_cultural_context").click

      # find now selected token
      @driver.find_element(:css, ".icon-token.subject_type_cultural_context")
    end

    it "displays correct icon for function term_type in subject selection" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  function")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_function").click

      # find now selected token
      @driver.find_element(:css, ".icon-token.subject_type_function")
    end

    it "displays correct icon for genre_form term_type in subject selection" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  genre_form")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_genre_form").click

      # find now selected token
      @driver.find_element(:css, ".icon-token.subject_type_genre_form")
    end
  
    it "displays correct icon for technique term_type in subject selection" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  technique")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_technique").click

      # find now selected token
      @driver.find_element(:css, ".icon-token.subject_type_technique")
    end

    it "displays correct icon for occupation term_type in subject selection" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  occupation")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_occupation").click

      # find now selected token
      @driver.find_element(:css, ".icon-token.subject_type_occupation")
    end

    it "displays correct icon for style_period term_type in subject selection" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  style_period")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_style_period").click

      # find now selected token
      @driver.find_element(:css, ".icon-token.subject_type_style_period")
    end

    it "displays correct icon for technique term_type in subject selection" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  technique")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_technique").click

      # find now selected token
      @driver.find_element(:css, ".icon-token.subject_type_technique")
    end
  
    it "displays correct icon for temporal term_type in subject selection" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  temporal")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_temporal").click

      # find now selected token
      @driver.find_element(:css, ".icon-token.subject_type_temporal")
    end

    it "displays correct icon for topical term_type in subject selection" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  topical")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_topical").click

      # find now selected token
      @driver.find_element(:css, ".icon-token.subject_type_topical")
    end

    it "displays correct icon for uniform_title term_type in subject selection" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  uniform_title")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_uniform_title").click

      # find now selected token
      @driver.find_element(:css, ".icon-token.subject_type_uniform_title")
    end
  end

  describe "resource with previously saved subject (edit view)" do
    it "displays correct icon (cultural_context) for subjects when loading a saved one" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  cultural_context")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_cultural_context").click

      # save form & reload page
      @driver.find_element(:css, "button.btn-primary").click
      @driver.navigate.refresh

      # look for icon class after form loads again
      @driver.find_element(:css, ".icon-token.subject_type_cultural_context")
    end

    it "displays correct icon (function) for subjects when loading a saved one" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  function")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_function").click

      # save form & reload page
      @driver.find_element(:css, "button.btn-primary").click
      @driver.navigate.refresh

      # look for icon class after form loads again
      @driver.find_element(:css, ".icon-token.subject_type_function")
    end
     
    it "displays correct icon (genre_form) for subjects when loading a saved one" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  genre_form")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_genre_form").click

      # save form & reload page
      @driver.find_element(:css, "button.btn-primary").click
      @driver.navigate.refresh

      # look for icon class after form loads again
      @driver.find_element(:css, ".icon-token.subject_type_genre_form")
    end
  
    it "displays correct icon (technique) for subjects when loading a saved one" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  technique")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_technique").click

      # save form & reload page
      @driver.find_element(:css, "button.btn-primary").click
      @driver.navigate.refresh

      # look for icon class after form loads again
      @driver.find_element(:css, ".icon-token.subject_type_technique")
    end

    it "displays correct icon (occupation) for subjects when loading a saved one" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  occupation")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_occupation").click

      # save form & reload page
      @driver.find_element(:css, "button.btn-primary").click
      @driver.navigate.refresh

      # look for icon class after form loads again
      @driver.find_element(:css, ".icon-token.subject_type_occupation")
    end

    it "displays correct icon (style_period) for subjects when loading a saved one" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  style_period")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_style_period").click

      # save form & reload page
      @driver.find_element(:css, "button.btn-primary").click
      @driver.navigate.refresh

      # look for icon class after form loads again
      @driver.find_element(:css, ".icon-token.subject_type_style_period")
    end
  
    it "displays correct icon (temporal) for subjects when loading a saved one" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  temporal")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_temporal").click

      # save form & reload page
      @driver.find_element(:css, "button.btn-primary").click
      @driver.navigate.refresh

      # look for icon class after form loads again
      @driver.find_element(:css, ".icon-token.subject_type_temporal")
    end

    it "displays correct icon (topical) for subjects when loading a saved one" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  topical")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_topical").click

      # save form & reload page
      @driver.find_element(:css, "button.btn-primary").click
      @driver.navigate.refresh

      # look for icon class after form loads again
      @driver.find_element(:css, ".icon-token.subject_type_topical")
    end
  
    it "displays correct icon (uniform_title) for subjects when loading a saved one" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  uniform_title")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_uniform_title").click

      # save form & reload page
      @driver.find_element(:css, "button.btn-primary").click
      @driver.navigate.refresh

      # look for icon class after form loads again
      @driver.find_element(:css, ".icon-token.subject_type_uniform_title")
    end
  end

  describe "resource with previously saved subject (show view)" do
    it "displays correct icon (cultural_context) for subjects when loading a saved one" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  cultural_context")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_cultural_context").click

      # save form & reload page
      @driver.find_element(:css, "button.btn-primary").click
      @driver.navigate.refresh

      # navigate to show page
      @driver.find_element(:css, ".breadcrumb li:nth-of-type(3) a").click

      # look for icon class after form loads again
      @driver.find_element(:css, ".icon-token.subject_type_cultural_context")
    end

    it "displays correct icon (function) for subjects when loading a saved one" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  function")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_function").click

      # save form & reload page
      @driver.find_element(:css, "button.btn-primary").click
      @driver.navigate.refresh

      # navigate to show page
      @driver.find_element(:css, ".breadcrumb li:nth-of-type(3) a").click

      # look for icon class after form loads again
      @driver.find_element(:css, ".icon-token.subject_type_function")
    end

     it "displays correct icon (genre_form) for subjects when loading a saved one" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  genre_form")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_genre_form").click

      # save form & reload page
      @driver.find_element(:css, "button.btn-primary").click
      @driver.navigate.refresh

      # navigate to show page
      @driver.find_element(:css, ".breadcrumb li:nth-of-type(3) a").click

      # look for icon class after form loads again
      @driver.find_element(:css, ".icon-token.subject_type_genre_form")
    end    

    it "displays correct icon (technique) for subjects when loading a saved one" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  technique")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_technique").click

      # save form & reload page
      @driver.find_element(:css, "button.btn-primary").click
      @driver.navigate.refresh

      # navigate to show page
      @driver.find_element(:css, ".breadcrumb li:nth-of-type(3) a").click

      # look for icon class after form loads again
      @driver.find_element(:css, ".icon-token.subject_type_technique")
    end

    it "displays correct icon (occupation) for subjects when loading a saved one" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  occupation")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_occupation").click

      # save form & reload page
      @driver.find_element(:css, "button.btn-primary").click
      @driver.navigate.refresh

      # navigate to show page
      @driver.find_element(:css, ".breadcrumb li:nth-of-type(3) a").click

      # look for icon class after form loads again
      @driver.find_element(:css, ".icon-token.subject_type_occupation")
    end

     it "displays correct icon (style_period) for subjects when loading a saved one" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  style_period")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_style_period").click

      # save form & reload page
      @driver.find_element(:css, "button.btn-primary").click
      @driver.navigate.refresh

      # navigate to show page
      @driver.find_element(:css, ".breadcrumb li:nth-of-type(3) a").click

      # look for icon class after form loads again
      @driver.find_element(:css, ".icon-token.subject_type_style_period")
    end    

    it "displays correct icon (technique) for subjects when loading a saved one" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  technique")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_technique").click

      # save form & reload page
      @driver.find_element(:css, "button.btn-primary").click
      @driver.navigate.refresh

      # navigate to show page
      @driver.find_element(:css, ".breadcrumb li:nth-of-type(3) a").click

      # look for icon class after form loads again
      @driver.find_element(:css, ".icon-token.subject_type_technique")
    end
     
    it "displays correct icon (temporal) for subjects when loading a saved one" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  temporal")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_temporal").click

      # save form & reload page
      @driver.find_element(:css, "button.btn-primary").click
      @driver.navigate.refresh

      # navigate to show page
      @driver.find_element(:css, ".breadcrumb li:nth-of-type(3) a").click

      # look for icon class after form loads again
      @driver.find_element(:css, ".icon-token.subject_type_temporal")
    end

    it "displays correct icon (topical) for subjects when loading a saved one" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  topical")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_topical").click

      # save form & reload page
      @driver.find_element(:css, "button.btn-primary").click
      @driver.navigate.refresh

      # navigate to show page
      @driver.find_element(:css, ".breadcrumb li:nth-of-type(3) a").click

      # look for icon class after form loads again
      @driver.find_element(:css, ".icon-token.subject_type_topical")
    end    

    it "displays correct icon (uniform_title) for subjects when loading a saved one" do
      # click on Add Subject button
      @driver.find_element(:css, "#resource_subjects_ button").click

      # select input box and type "a" to bring up a list of subjects
      @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "  uniform_title")

      # click on option in search bar to select it
      @driver.find_element(:css, ".subject_type_uniform_title").click

      # save form & reload page
      @driver.find_element(:css, "button.btn-primary").click
      @driver.navigate.refresh

      # navigate to show page
      @driver.find_element(:css, ".breadcrumb li:nth-of-type(3) a").click

      # look for icon class after form loads again
      @driver.find_element(:css, ".icon-token.subject_type_uniform_title")
    end
  end
end

