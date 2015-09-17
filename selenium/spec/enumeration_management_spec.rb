require_relative 'spec_helper'

describe "Enumeration Management" do
  before(:all) do
    @repo = create(:repo, :repo_code => "enum_test_#{Time.now.to_i}")
    set_repo @repo

    @driver = Driver.new.login($admin)
  end


  after(:all) do
    @driver.quit
  end


  it "lets you add a new value to an enumeration" do
    @driver.find_element(:link, 'System').click
    @driver.find_element(:link, "Manage Controlled Value Lists").click

    enum_select = @driver.find_element(:id => "enum_selector")
    enum_select.select_option_with_text("Accession Acquisition Type (accession_acquisition_type)")

    # Wait for the table of enumerations to load
    @driver.find_element(:css, '.enumeration-list')

    @driver.find_element(:link, 'Create Value').click
    @driver.clear_and_send_keys([:id, "enumeration_value_"], "manna\n")

    @driver.find_element_with_text('//td', /^manna$/)
  end


  it "lets you delete a value from an enumeration" do
    manna = @driver.find_element_with_text('//tr', /manna/)
    manna.find_element(:link, 'Delete').click

    @driver.find_element(:css => "form#delete_enumeration button[type='submit']").click

    @driver.find_element_with_text('//div', /Value Deleted/)

    @driver.ensure_no_such_element(:xpath, '//td[contains(text(), "manna")]')
  end


  it "lets you merge one value into another in an enumeration" do
    enum_a = "EnumA_#{Time.now.to_i}_#{$$}"
    enum_b = "EnumB_#{Time.now.to_i}_#{$$}"

    # create enum A
    @driver.find_element(:link, 'Create Value').click
    @driver.clear_and_send_keys([:id, "enumeration_value_"], "#{enum_a}\n")

    # create enum B
    @driver.find_element(:link, 'Create Value').click
    @driver.clear_and_send_keys([:id, "enumeration_value_"], "#{enum_b}\n")

    # merge enum B into A
    @driver.find_element(:xpath, "//a[contains(@href, \"#{enum_b}\")][contains(text(), \"Merge\")]").click

    #merge form is eventually displayed
    merge_form = @driver.find_element(:id, 'merge_enumeration')
    merge_form.find_element(:id, 'merge_into').select_option_with_text(enum_a)

    @driver.click_and_wait_until_gone(:css => "form#merge_enumeration button[type='submit']")

    @driver.find_element_with_text('//div', /Value Merged/)

    @driver.ensure_no_such_element(:xpath, "//td[contains(text(), \"#{enum_b}\")]")
  end


  it "lets you set a default enumeration (date_type)" do
    @driver.find_element(:link, 'System').click
    @driver.find_element(:link, "Manage Controlled Value Lists").click

    enum_select = @driver.find_element(:id => "enum_selector")
    enum_select.select_option_with_text("Date Type (date_type)")

    # Wait for the table of enumerations to load
    @driver.find_element(:css, '.enumeration-list')

    while true
      inclusive_dates = @driver.find_element_with_text('//tr', /Inclusive Dates/)
      default_btn = inclusive_dates.find_elements(:link, 'Set as Default')

      if default_btn[0]
        default_btn[0].click
        # Keep looping until the 'Set as Default' button is gone
        @driver.wait_for_ajax
        sleep 3
      else
        break
      end
    end

    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Accession").click

    @driver.find_element(:css => '#accession_dates_ .subrecord-form-heading .btn:not(.show-all)').click

    date_type_select = @driver.find_element(:id => "accession_dates__0__date_type_")
    selected_type = date_type_select.get_select_value
    selected_type.should eq 'inclusive'

    # ensure that the correct subform is loading:
    subform = @driver.find_element(:css => '.date-type-subform')
    subform.find_element_with_text('//label', /Begin/)
    subform.find_element_with_text('//label', /End/)

    @driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")
  end

  it "lets you add a new value to an enumeration, reorder it and then you can use it" do
    @driver.find_element(:link, 'System').click
    @driver.find_element(:link, "Manage Controlled Value Lists").click

    enum_select = @driver.find_element(:id => "enum_selector")
    enum_select.select_option_with_text("Collection Management Processing Priority (collection_management_processing_priority)")

    # Wait for the table of enumerations to load
    @driver.find_element(:css, '.enumeration-list')

    @driver.find_element(:link, 'Create Value').click
    @driver.clear_and_send_keys([:id, "enumeration_value_"], "IMPORTANT.\n")

    @driver.find_element_with_text('//td', /^IMPORTANT\.$/)

    # lets move important up the list
    3.times do
      @driver.find_element_with_text('//tr', /IMPORTANT/).find_element(:css, '.position-up').click
    end

    # now lets make sure it's there
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Accession").click

    cm_accession_title = "CM Punk TEST"
    @driver.clear_and_send_keys([:id, "accession_title_"], cm_accession_title)
    @driver.complete_4part_id("accession_id_%d_", @driver.generate_4part_id)
    @driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
    @driver.clear_and_send_keys([:id, "accession_content_description_"], "STUFFZ")
    @driver.clear_and_send_keys([:id, "accession_condition_description_"], "stuffy")

    #now add collection management
    @driver.find_element(:css => '#accession_collection_management_ .subrecord-form-heading .btn:not(.show-all)').click

    # our new value should be #1!
    @driver.find_element(:id => "accession_collection_management__processing_priority_").text.each_line.first.chomp.should eq("IMPORTANT.")

    @driver.find_element(:id => "accession_collection_management__processing_priority_").select_option("IMPORTANT.")
    @driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

    @driver.click_and_wait_until_gone(:link => cm_accession_title)

    assert(5) { @driver.find_element(:css => '#accession_collection_management__accordian div:last-child').text.include?("IMPORTANT.") }
  end

  it "lets you see how many times the term has been used and search for it" do
    @driver.find_element(:link, 'System').click
    @driver.find_element(:link, "Manage Controlled Value Lists").click
    run_index_round

    enum_select = @driver.find_element(:id => "enum_selector")
    enum_select.select_option_with_text("Collection Management Processing Priority (collection_management_processing_priority)")
    @driver.wait_for_ajax
    @driver.find_element(:link, "1 related item.")


  end

  it "lets you suppress an enumeration value" do
    @driver.find_element(:link, 'System').click
    @driver.find_element(:link, "Manage Controlled Value Lists").click

    enum_select = @driver.find_element(:id => "enum_selector")
    enum_select.select_option_with_text("Collection Management Processing Priority (collection_management_processing_priority)")

    # Wait for the table of enumerations to load
    @driver.find_element(:css, '.enumeration-list')

    @driver.find_element(:link, 'Create Value').click
    @driver.clear_and_send_keys([:id, "enumeration_value_"], "fooman\n")

    foo = @driver.find_element_with_text('//tr', /fooman/)
    foo.find_element(:link, "Suppress").click

    assert(5) {
      @driver.find_element_with_text('//tr', /fooman/).find_element(:link, "Unsuppress").should_not be_nil
    }
    # now lets make sure it's there
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Accession").click

    cm_accession_title = "CM Punk TEST2"
    @driver.clear_and_send_keys([:id, "accession_title_"], cm_accession_title)
    @driver.complete_4part_id("accession_id_%d_", @driver.generate_4part_id)
    @driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
    @driver.clear_and_send_keys([:id, "accession_content_description_"], "STUFFZ")
    @driver.clear_and_send_keys([:id, "accession_condition_description_"], "stuffy")

    #now add collection management
    @driver.find_element(:css => '#accession_collection_management_ .subrecord-form-heading .btn:not(.show-all)').click

    # make sure our suppressed value is not present
    @driver.ensure_no_such_element(:xpath, "//option[@value='fooman']")

    # lets just finish up making the record and move on, shall we?
    @driver.find_element(:id => "accession_collection_management__processing_priority_").select_option("IMPORTANT.")
    @driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")
  end

end
