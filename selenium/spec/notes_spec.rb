require_relative 'spec_helper'

describe "Notes" do

  before(:all) do   
    @repo = create(:repo, :repo_code => "notes_test_#{Time.now.to_i}")
    set_repo @repo

    @resource = create(:resource)
    archivist_user = create_user(@repo => ['repository-archivists'])

    @driver = Driver.get
    @driver.login_to_repo(archivist_user, @repo)

    @driver.get_edit_page(@resource)
    @driver.find_element(:id, "resource_title_")
  end


  after(:all) do
    @driver.quit
  end


  it "can attach notes to resources" do
    add_note = proc do |type|
      @driver.find_element(:css => '#notes .subrecord-form-heading .btn.add-note').click
      @driver.find_last_element(:css => '#notes select.top-level-note-type:last-of-type').select_option(type)
    end

    3.times do
      add_note.call("note_multipart")
    end

    @driver.blocking_find_elements(:css => '#notes > .subrecord-form-container > .subrecord-form-list > li').length.should eq(3)
  end


  it "confirms before removing a note entry" do
    notes = @driver.blocking_find_elements(:css =>  '#notes > .subrecord-form-container > .subrecord-form-list > li')

    notes[0].find_element(:css => '.subrecord-form-remove').click

    # Get a confirmation
    @driver.find_element(:css => '.subrecord-form-removal-confirmation')

    # Now remove the second note
    notes[1].find_element(:css => '.subrecord-form-remove').click

    # Verify that the first confirmation is now gone
    @driver.find_elements(:css => '.subrecord-form-removal-confirmation').length.should be < 2

    # Confirm
    @driver.click_and_wait_until_gone(:css => '.subrecord-form-removal-confirmation .btn-primary')

    # Take out the first note too
    notes[0].find_element(:css => '.subrecord-form-remove').click
    @driver.click_and_wait_until_gone(:css => '.subrecord-form-removal-confirmation .btn-primary')

    # One left!
    @driver.blocking_find_elements(:css => '#notes > .subrecord-form-container > .subrecord-form-list > li').length.should eq(1)

    # Fill it out
    @driver.clear_and_send_keys([:id, 'resource_notes__2__label_'],
                                "A multipart note")

    @driver.execute_script("$('#resource_notes__2__subnotes__0__content_').data('CodeMirror').setValue('Some note content')")
    @driver.execute_script("$('#resource_notes__2__subnotes__0__content_').data('CodeMirror').save()")


    # Save the resource
    @driver.click_and_wait_until_gone(:css => "form#resource_form button[type='submit']")

    @driver.find_element(:link, 'Close Record').click
  end


  it "can edit an existing resource note to add subparts after saving" do
    @driver.attempt(10) { |driver|
      driver.get("#{$frontend}#{@resource.uri.sub(/\/repositories\/\d+/, '')}/edit")
      driver.find_element(:id, "resource_title_")
    }

    notes = @driver.blocking_find_elements(:css => '#notes .subrecord-form-fields')

    # Add a sub note
    notes[0].find_element(:css => '.collapse-subrecord-toggle').click
    assert(5) { notes[0].find_element(:css => '.subrecord-form-heading .btn:not(.show-all)').click }
    @driver.scroll_into_view(notes[0].find_last_element(:css => 'select.multipart-note-type'))
    notes[0].find_last_element(:css => 'select.multipart-note-type').select_option('note_chronology')

    @driver.find_element(:id => 'resource_notes__0__subnotes__2__title_')
    @driver.clear_and_send_keys([:id, 'resource_notes__0__subnotes__2__title_'], "Chronology title")


    notes[0].find_element(:css => '.subrecord-form-heading .btn:not(.show-all)').click
    notes[0].find_last_element(:css => 'select.multipart-note-type').select_option('note_definedlist')

    @driver.clear_and_send_keys([:id, 'resource_notes__0__subnotes__3__title_'], "Defined list")

    2.times do
      @driver.find_element(:id => 'resource_notes__0__subnotes__3__title_').
        containing_subform.
        find_element(:css => '.add-item-btn').
        click
    end

    [4, 5]. each do |i|
      ["label", "value"].each do |field|
        @driver.clear_and_send_keys([:id, "resource_notes__0__subnotes__3__items__#{i}__#{field}_"],
                                    "pogo")
      end
    end

    # Save the resource
    @driver.find_element(:css => "form#resource_form button[type='submit']").click
    @driver.find_element(:link, 'Close Record').click

    @driver.find_element_with_text("//div", /pogo/)
  end


  it "can add a top-level bibliography too" do
    
    @driver.get_edit_page(@resource)

    bibliography_content = "Top-level bibliography content"

    @driver.find_element(:css => '#notes > .subrecord-form-heading .btn.add-note').click
    @driver.find_last_element(:css => 'select.top-level-note-type').select_option("note_bibliography")

    @driver.clear_and_send_keys([:id, 'resource_notes__6__label_'], "Top-level bibliography label")
    @driver.execute_script("$('#resource_notes__6__content__0_').data('CodeMirror').setValue('#{bibliography_content}')")
    @driver.execute_script("$('#resource_notes__6__content__0_').data('CodeMirror').save()")

    @driver.execute_script("$('#resource_notes__6__content__0_').data('CodeMirror').toTextArea()")
    @driver.find_element(:id => "resource_notes__6__content__0_").attribute("value").should eq(bibliography_content)

    form = @driver.find_element(:id => 'resource_notes__6__label_').nearest_ancestor('div[contains(@class, "subrecord-form-container")]')

    2.times do
      form.find_element(:css => '.add-item-btn').click
    end

    @driver.clear_and_send_keys([:id, 'resource_notes__6__items__7_'], "Top-level bib item 1")
    @driver.clear_and_send_keys([:id, 'resource_notes__6__items__8_'], "Top-level bib item 2")
  end


  it "can wrap note content text with EAD mark up" do
    # expand the first note
    @driver.find_element(:css => '#notes .collapse-subrecord-toggle').click
    @driver.wait_for_ajax

    @driver.find_element_orig(:css, '#resource_notes__0__subnotes__0__content_').wait_for_class("initialised");
    # select some text
    @driver.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').setValue('ABC')")
    @driver.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').setSelection({line: 0, ch: 0}, {line: 0, ch: 3})")

    # select a tag to wrap the text
    @driver.find_element(:css => "select.mixed-content-wrap-action").select_option("blockquote")
    @driver.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').save()")
    @driver.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').toTextArea()")
    @driver.find_element(:id => "resource_notes__0__subnotes__0__content_").attribute("value").should eq("<blockquote>ABC</blockquote>")

    # Save the resource
    @driver.find_element(:css => "form#resource_form button[type='submit']").click
    @driver.find_element(:link, 'Close Record').click
  end


  it "can add a deaccession record" do
    @driver.get_edit_page(@resource)

    @driver.find_element(:css => '#resource_deaccessions_ .subrecord-form-heading .btn:not(.show-all)').click

    @driver.find_element(:id => 'resource_deaccessions__0__date__label_').get_select_value.should eq("deaccession")

    @driver.clear_and_send_keys([:id, 'resource_deaccessions__0__description_'], "Lalala describing the deaccession")
    @driver.find_element(:css => "#resource_deaccessions__0__date__date_type_").select_option("single")
    @driver.clear_and_send_keys([:id, 'resource_deaccessions__0__date__begin_'], "2012-05-14")

    # Save the resource
    @driver.find_element(:css => "form#resource_form button[type='submit']").click
    @driver.find_element(:link, 'Close Record').click

    @driver.blocking_find_elements(:css => '#resource_deaccessions_').length.should eq(1)
  end


  it "types for rights statements are correct" do
    @driver.get_edit_page(@resource)

    # add rights statement
    @driver.find_element(:css => '#resource_rights_statements_ .subrecord-form-heading button').click

    # add rights statement note
    @driver.find_element(:css => '#rights_statement_notes .subrecord-form-heading .add-note').click

    # note types should be rights note type only
    @driver.find_elements(:css => '#rights_statement_notes .top-level-note-type option').each_with_index do |option_element, i|
      if i == 0
        option_element.attribute('value').should eq("")
      else
        option_element.attribute('value').should eq("note_rights_statement")
      end
    end

    @driver.find_element(:css, "#rights_statement_notes .top-level-note-type").select_option_with_text("Additional Information")
    @driver.find_element(:id, "resource_rights_statements__0__notes__0__type_").get_select_value.should eq("additional_information")

    # add rights statement act
    @driver.find_element(:css => '#resource_rights_statements__0__acts_ .subrecord-form-heading button').click

    # add rights statement act note
    @driver.find_element(:css => '#resource_rights_statements__0__acts_ .subrecord-form-heading .add-note').click

    # note types should be act note type only
    @driver.find_elements(:css => '#resource_rights_statements__0__acts_ .top-level-note-type option').each_with_index do |option_element, i|
      if i == 0
        option_element.attribute('value').should eq("")
      else
        option_element.attribute('value').should eq("note_rights_statement_act")
      end
    end

    @driver.find_element(:css, "#resource_rights_statements__0__acts_ .top-level-note-type").select_option_with_text("Additional Information")
    @driver.find_element(:id, "resource_rights_statements__0__acts__0__notes__0__type_").get_select_value.should eq("additional_information")

    # Force a save
    @driver.find_element(:css => "form#resource_form button[type='submit']").click

    # And check things again
    @driver.find_element(:id, "resource_rights_statements__0__notes__0__type_").get_select_value.should eq("additional_information")
    @driver.find_element(:id, "resource_rights_statements__0__acts__0__notes__0__type_").get_select_value.should eq("additional_information")

    # Add a second note, are they cool?
    @driver.find_element(:css => '#rights_statement_notes .subrecord-form-heading .add-note').click
    @driver.find_elements(:css => '#rights_statement_notes .top-level-note-type option').each_with_index do |option_element, i|
      if i == 0
        option_element.attribute('value').should eq("")
      else
        option_element.attribute('value').should eq("note_rights_statement")
      end
    end
    @driver.find_element(:css, "#rights_statement_notes .top-level-note-type").select_option_with_text("Additional Information")
    @driver.find_element(:id, "resource_rights_statements__0__notes__2__type_").get_select_value.should eq("additional_information")

    @driver.find_element(:css => '#rights_statement_act_notes.initialised .add-note').click
    @driver.find_elements(:css => '#resource_rights_statements__0__acts_ .top-level-note-type option').each_with_index do |option_element, i|
      if i == 0
        option_element.attribute('value').should eq("")
      else
        option_element.attribute('value').should eq("note_rights_statement_act")
      end
    end
    @driver.find_element(:css, "#resource_rights_statements__0__acts_ .top-level-note-type").select_option_with_text("Additional Information")
    @driver.find_element(:id, "resource_rights_statements__0__acts__0__notes__2__type_").get_select_value.should eq("additional_information")


    @driver.click_and_wait_until_gone(:css => '.btn.btn-cancel.btn-default')
  end


  it "can attach notes to archival objects" do
    @driver.navigate.to("#{$frontend}")
    # Create a resource
    @driver.find_element(:link, "Create").click
    @driver.click_and_wait_until_gone(:link, "Resource")

    @driver.clear_and_send_keys([:id, "resource_title_"], "a resource")
    @driver.complete_4part_id("resource_id_%d_")
    combo = @driver.find_element(:xpath => '//div[@class="combobox-container"][following-sibling::select/@id="resource_language_"]//input[@type="text"]');
    combo.clear
    combo.click
    combo.send_keys("eng")
    combo.send_keys(:tab)
    @driver.find_element(:id, "resource_level_").select_option("collection")
    @driver.clear_and_send_keys([:id, "resource_extents__0__number_"], "10")
    @driver.find_element(:id => "resource_extents__0__extent_type_").select_option("cassettes")

    @driver.find_element(:id => "resource_dates__0__date_type_").select_option("single")
    @driver.clear_and_send_keys([:id, "resource_dates__0__begin_"], "1978")

    @driver.click_and_wait_until_gone(:css => "form#resource_form button[type='submit']")

    # Give it a child AO
    @driver.click_and_wait_until_gone(:link, "Add Child")
    @driver.wait_for_ajax

    @driver.clear_and_send_keys([:id, "archival_object_title_"], "An Archival Object with notes")
    @driver.find_element(:id, "archival_object_level_").select_option("item")


    # Add some notes to it
    add_note = proc do |type|
      @driver.find_element(:css => '#notes .subrecord-form-heading .btn.add-note').click
      @driver.find_last_element(:css => '#notes select.top-level-note-type').select_option(type)
    end

    3.times do
      add_note.call("note_multipart")
    end

    @driver.blocking_find_elements(:css => '#notes > .subrecord-form-container > .subrecord-form-list > li').length.should eq(3)


    @driver.click_and_wait_until_gone(:css => '.btn.btn-cancel.btn-default')
  end


  it "can attach special notes to digital objects" do
    @driver.navigate.to("#{$frontend}")

    @driver.find_element(:link, "Create").click
    @driver.click_and_wait_until_gone(:link, "Digital Object")

    @driver.clear_and_send_keys([:id, "digital_object_title_"], "A digital object with notes")
    @driver.clear_and_send_keys([:id, "digital_object_digital_object_id_"],(Digest::MD5.hexdigest("#{Time.now}")))

    # Add a Summary note
    @driver.find_element(:css => '#digital_object_notes .subrecord-form-heading .btn.add-note').click
    @driver.find_last_element(:css => '#digital_object_notes select.top-level-note-type').select_option_with_text("Summary")

    @driver.clear_and_send_keys([:id, 'digital_object_notes__0__label_'], "Summary label")
    @driver.execute_script("$('#digital_object_notes__0__content__0_').data('CodeMirror').setValue('Summary content')")
    @driver.execute_script("$('#digital_object_notes__0__content__0_').data('CodeMirror').save()")

    @driver.execute_script("$('#digital_object_notes__0__content__0_').data('CodeMirror').toTextArea()")
    @driver.find_element(:id => "digital_object_notes__0__content__0_").attribute("value").should eq("Summary content")

    @driver.click_and_wait_until_gone(:css => "form#new_digital_object button[type='submit']")
  end

end
