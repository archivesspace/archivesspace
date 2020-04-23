# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Resources and archival objects' do
  before(:all) do
    @repo = create(:repo, repo_code: "resources_test_#{Time.now.to_i}")
    set_repo @repo

    @accession = create(:accession,
                        collection_management: build(:collection_management))

    @resource = create(:resource)

    @archival_object = create(:archival_object, resource: { 'ref' => @resource.uri })

    @user = create_user(@repo => ['repository-managers'])
    @driver = Driver.get.login_to_repo(@user, @repo)
  end

  before(:each) do
    @driver.go_home
  end

  after(:all) do
    @driver ? @driver.quit : next
  end

  it 'can spawn a resource from an existing accession' do
    @driver.get_view_page(@accession)

    # Spawn a resource from the accession we just created
    @driver.find_element(:link, 'Spawn').click
    @driver.find_element(:link, 'Resource').click

    # The relationship back to the original accession is prepopulated
    expect(@driver.find_element(css: 'div.accession').text).to match(@accession.title)

    @driver.complete_4part_id('resource_id_%d_')

    @driver.find_element(:id, 'resource_level_').select_option('collection')

    res_lang_combo = @driver.find_element(xpath: '//*[@id="resource_lang_materials__0_"]/div[1]/div/div/div/div[1]/div/div/div/input[@type="text"]')
    res_lang_combo.clear
    res_lang_combo.click
    res_lang_combo.send_keys('eng')
    res_lang_combo.send_keys(:tab)

    fa_lang_combo = @driver.find_element(xpath: '//*[@id="finding_aid"]/div/div/fieldset/div[@class="form-group required"]/div[@class="col-sm-9"]/div[@class="combobox-container"][following-sibling::select/@id="resource_finding_aid_language_"]//input[@type="text"]')
    fa_lang_combo.clear
    fa_lang_combo.click
    fa_lang_combo.send_keys('eng')
    fa_lang_combo.send_keys(:tab)

    fa_script_combo = @driver.find_element(xpath: '//*[@id="finding_aid"]/div/div/fieldset/div[@class="form-group required"]/div[@class="col-sm-9"]/div[@class="combobox-container"][following-sibling::select/@id="resource_finding_aid_script_"]//input[@type="text"]')
    fa_script_combo.clear
    fa_script_combo.click
    fa_script_combo.send_keys('Latn')
    fa_script_combo.send_keys(:tab)

    # no collection managment
    expect(@driver.find_elements(:id, 'resource_collection_management__cataloged_note_').length).to eq(0)

    # condition and content descriptions have come across as notes fields
    notes_toggle = @driver.blocking_find_elements(css: '#notes .collapse-subrecord-toggle')
    notes_toggle[0].click
    @driver.wait_for_ajax

    @driver.find_element_orig(:css, '#resource_notes__0__subnotes__0__content_').wait_for_class('initialised')
    @driver.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').toTextArea()")
    assert(5) { expect(@driver.find_element(id: 'resource_notes__0__subnotes__0__content_').attribute('value')).to eq(@accession.content_description) }

    notes_toggle[1].click

    expect(@driver.find_element(id: 'resource_notes__1__content__0_').text).to match(@accession.condition_description)

    @driver.find_element(id: 'resource_dates__0__date_type_').select_option('single')
    @driver.clear_and_send_keys([:id, 'resource_dates__0__begin_'], '1978')

    @driver.clear_and_send_keys([:id, 'resource_extents__0__number_'], '10')
    @driver.find_element(id: 'resource_extents__0__extent_type_').select_option('cassettes')

    @driver.click_and_wait_until_gone(css: "form#resource_form button[type='submit']")

    # Success!
    expect(@driver.find_element_with_text('//div', /Resource .* created/)).not_to be_nil
    expect(@driver.find_element(:id, 'resource_dates__0__begin_').attribute('value')).to eq('1978')
  end

  it 'reports errors and warnings when creating an invalid Resource' do
    @driver.find_element(:link, 'Create').click
    @driver.click_and_wait_until_gone(:link, 'Resource')
    @driver.find_element(:id, 'resource_title_').clear
    @driver.find_element(css: "form#resource_form button[type='submit']").click

    @driver.find_element_with_text('//div[contains(@class, "error")]', /Identifier - Property is required but was missing/)
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Title - Property is required but was missing/)
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Number - Property is required but was missing/)
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Type - Property is required but was missing/)
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Language of Description - Property is required but was missing/)
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Script of Description - Property is required but was missing/)

    @driver.click_and_wait_until_gone(:css, 'a.btn.btn-cancel')
  end

  it 'can create a resource' do
    resource_title = "Pony <emph render='italic'>Express</emph>"
    resource_stripped = 'Pony Express'
    resource_regex = /^.*?\bPony\b.*?$/m

    @driver.find_element(:link, 'Create').click
    @driver.click_and_wait_until_gone(:link, 'Resource')

    @driver.clear_and_send_keys([:id, 'resource_title_'], resource_title)
    @driver.complete_4part_id('resource_id_%d_')

    fa_lang_combo = @driver.find_element(xpath: '//*[@id="finding_aid"]/div/div/fieldset/div[@class="form-group required"]/div[@class="col-sm-9"]/div[@class="combobox-container"][following-sibling::select/@id="resource_finding_aid_language_"]//input[@type="text"]')
    fa_lang_combo.clear
    fa_lang_combo.click
    fa_lang_combo.send_keys('eng')
    fa_lang_combo.send_keys(:tab)

    fa_script_combo = @driver.find_element(xpath: '//*[@id="finding_aid"]/div/div/fieldset/div[@class="form-group required"]/div[@class="col-sm-9"]/div[@class="combobox-container"][following-sibling::select/@id="resource_finding_aid_script_"]//input[@type="text"]')
    fa_script_combo.clear
    fa_script_combo.click
    fa_script_combo.send_keys('Latn')
    fa_script_combo.send_keys(:tab)

    @driver.find_element(id: 'resource_dates__0__date_type_').select_option('single')
    @driver.clear_and_send_keys([:id, 'resource_dates__0__begin_'], '1978')
    @driver.find_element(:id, 'resource_level_').select_option('collection')

    combo = @driver.find_element(xpath: '//*[@id="resource_lang_materials__0_"]/div[1]/div/div/div/div[1]/div/div/div/input[@type="text"]')
    combo.clear
    combo.click
    combo.send_keys('eng')
    combo.send_keys(:tab)

    @driver.clear_and_send_keys([:id, 'resource_extents__0__number_'], '10')
    @driver.find_element(id: 'resource_extents__0__extent_type_').select_option('cassettes')
    @driver.find_element(css: "form#resource_form button[type='submit']").click

    # The new Resource shows up on the tree
    assert(5) do
      sleep 2
      expect(tree_current.text.strip).to match(resource_regex)
    end
  end

  it 'reports warnings when updating a Resource with invalid data' do
    @driver.get_edit_page(@resource)

    @driver.find_element(:id, 'resource_title_')
    @driver.clear_and_send_keys([:id, 'resource_title_'], '')

    sleep(5)
    if @driver.find_element(css: "form#resource_form button[type='submit']").enabled?
      sleep(5)
      @driver.find_elements(css: "form#resource_form button[type='submit']")[1].click
    end

    expect do
      @driver.find_element_with_text('//div[contains(@class, "error")]', /Title - Property is required but was missing/)
    end.not_to raise_error

    @driver.click_and_wait_until_gone(:css, 'a.btn.btn-cancel')
  end

  it 'reports errors if adding an empty child to a Resource' do
    @driver.get_edit_page(@resource)

    @driver.find_element(:link, 'Add Child').click
    @driver.wait_for_ajax
    @driver.clear_and_send_keys([:id, 'archival_object_title_'], ' ')
    @driver.wait_for_ajax

    sleep(5) unless @driver.find_element(id: 'createPlusOne')
    # False start: create an object without filling it out
    @driver.find_element(id: 'createPlusOne').click

    @driver.find_element_with_text('//div[contains(@class, "error")]', /Level of Description - Property is required but was missing/)

    # click on another node
    tree_click(tree_node(@resource))

    @driver.click_and_wait_until_gone(:id, 'dismissChangesButton')
  end

  it 'reports error if title is empty and no date is provided' do
    @driver.get("#{$frontend}#{@resource.uri.sub(%r{/repositories/\d+}, '')}/edit")

    @driver.find_element(:link, 'Add Child').click
    @driver.wait_for_ajax
    @driver.find_element(:id, 'archival_object_level_').select_option('item')
    @driver.clear_and_send_keys([:id, 'archival_object_title_'], '')
    @driver.wait_for_ajax

    # False start: create an object without filling it out
    @driver.find_element(id: 'createPlusOne').click
    @driver.find_element_with_text('//div[contains(@class, "error")]', /Dates - one or more required \(or enter a Title\)/i)

    @driver.find_element_with_text('//div[contains(@class, "error")]', /Title - must not be an empty string \(or enter a Date\)/i)

    tree_click(tree_node(@resource))
    @driver.click_and_wait_until_gone(:id, 'dismissChangesButton')
  end

  it 'can create a new digital object instance with a note to a resource' do
    @driver.get_edit_page(@resource)

    # Wait for the form to load in
    @driver.find_element(css: "form#resource_form button[type='submit']")
    @driver.find_element(css: '#resource_instances_ .subrecord-form-heading .btn[data-instance-type="digital-instance"]').click

    # Wait for the linker to initialise to make sure the dropdown click events are bound
    @driver.find_hidden_element(css: '#resource_instances__0__digital_object__ref_.initialised')

    elt = @driver.find_element(css: "div[data-id-path='resource_instances__0__digital_object_']")

    elt.find_element(css: 'a.dropdown-toggle').click
    @driver.wait_for_dropdown
    elt.find_element(css: 'a.linker-create-btn').click

    modal = @driver.find_element(css: '#resource_instances__0__digital_object__ref__modal')

    modal.clear_and_send_keys([:id, 'digital_object_title_'], 'digital_object_title')
    modal.clear_and_send_keys([:id, 'digital_object_digital_object_id_'], Digest::MD5.hexdigest(Time.now.to_s))

    @driver.execute_script("$('#digital_object_notes.initialised .subrecord-form-heading .btn.add-note').focus()")
    modal.find_element(css: '#digital_object_notes.initialised .subrecord-form-heading .btn.add-note').click
    modal.find_last_element(css: '#digital_object_notes select.top-level-note-type').select_option_with_text('Summary')

    modal.clear_and_send_keys([:id, 'digital_object_notes__0__label_'], 'Summary label')
    @driver.execute_script("$('#digital_object_notes__0__content__0_').data('CodeMirror').setValue('Summary content')")
    @driver.execute_script("$('#digital_object_notes__0__content__0_').data('CodeMirror').save()")

    @driver.execute_script("$('#digital_object_notes__0__content__0_').data('CodeMirror').toTextArea()")
    expect(@driver.find_element(id: 'digital_object_notes__0__content__0_').attribute('value')).to eq('Summary content')

    modal.find_element(:id, 'createAndLinkButton').click
    @driver.click_and_wait_until_gone(css: "form#resource_form button[type='submit']")

    @driver.find_element(:css, '.token-input-token .digital_object').click

    # so the subject is here now
    assert(5) { expect(@driver.find_element(:css, '.token-input-token .digital_object').text).to match(/digital_object_title/) }
  end


  # This guy is causing subsequent tests to fail with a missing locales file error.  Pending it until I have more time to investigate.
  xit 'can have a lot of associated records that do not show in the field but are not lost' do
    subjects = []
    accessions = []
    classifications = []
    dos = []
    instances = []
    agents = []

    10.times do |_i|
      subjects << create(:subject)
      accessions << create(:accession)
      classifications << create(:classification)
      dos << create(:digital_object)
      instances = dos.map { |d| { instance_type: 'digital_object', digital_object: { ref: d.uri } } }
      agents << create(:agent_person)
    end

    linked_agents = agents.map do |a|
      { ref: a.uri,
        role: 'creator',
        relator: generate(:relator),
        title: generate(:alphanumstr) }
    end

    resource = create(:resource,
                      linked_agents: linked_agents,
                      subjects: subjects.map { |s| { ref: s.uri } },
                      related_accessions: accessions.map { |a| { ref: a.uri } },
                      instances: instances,
                      classifications: classifications.map { |c| { ref: c.uri } })

    run_index_round

    # let's go to the edit page
    @driver.get_edit_page(resource)

    # Wait for the form to load in
    @driver.find_element(css: "form#resource_form button[type='submit']")

    # now lets make a small change...
    @driver.find_element(css: '#resource_extents_ .subrecord-form-heading .btn:not(.show-all)').click
    @driver.clear_and_send_keys([:id, 'resource_extents__1__number_'], '5')
    @driver.find_element(id: 'resource_extents__1__extent_type_').select_option('volumes')

    # submit it
    @driver.find_element(css: "form#resource_form button[type='submit']").click

    # no errors!
    expect(@driver.find_element_with_text('//div', /\bResource\b.*\bupdated\b/)).not_to be_nil

    # let's open all all the too-manys and make sure everything is still
    # there..
    @driver.find_elements(css: '.alert-too-many').each { |c| c.click }

    [subjects, accessions, classifications, dos].each do |klass|
      klass.each do |a|
        expect(@driver.find_element(id: a[:uri].gsub('/', '_')).text).to match(/#{ a[:display_title] }/)
      end
    end

    # agents are weird.
    linked_agents.each_with_index do |a, i|
      assert(5) { expect(@driver.find_element(css: "#resource_linked_agents__#{i}__role_").get_select_value).to eq(a[:role]) }
      if a.key?(:title)
        assert(5) { expect(@driver.find_element(css: "#resource_linked_agents__#{i}__title_").attribute('value')).to eq(a[:title]) }
      end
      assert(5) { expect(@driver.find_input_by_name("resource[linked_agents][#{i}][relator]").attribute('value')).to eq(a[:relator]) }
      assert(5) { expect(@driver.find_element(css: "#resource_linked_agents__#{i}_ .linker-wrapper .token-input-token").text).to match(/#{ agents[i][:primary_name] }/) }
    end

    # Delete the resource
    @driver.find_element(:css, '.delete-record.btn').click
    @driver.click_and_wait_until_gone(:css, '#confirmChangesModal #confirmButton')
  end

  it 'can edit a Resource, add a second Extent, then remove it' do
    @driver.get_edit_page(@resource)

    @driver.find_element(css: '#resource_extents_ .subrecord-form-heading .btn:not(.show-all)').click

    @driver.clear_and_send_keys([:id, 'resource_extents__1__number_'], '5')
    @driver.find_element(id: 'resource_extents__1__extent_type_').select_option('volumes')

    @driver.find_element(css: "form#resource_form button[type='submit']").click

    expect(@driver.find_element_with_text('//div', /\bResource\b.*\bupdated\b/)).not_to be_nil

    @driver.find_element(:link, 'Close Record').click

    # it can see two Extents on the saved Resource
    extent_headings = @driver.blocking_find_elements(css: '#resource_extents_ .panel-heading')

    expect(extent_headings.length).to eq 2
    assert(5) { expect(extent_headings[0].text).to match /^\d.*/ }
    assert(5) { expect(extent_headings[1].text).to match /^\d.*/ }

    # it can remove an Extent when editing a Resource
    @driver.get("#{$frontend}#{@resource.uri.sub(%r{/repositories/\d+}, '')}/edit")

    @driver.blocking_find_elements(css: '#resource_extents_ .subrecord-form-remove')[1].click
    @driver.find_element(css: '#resource_extents_ .confirm-removal').click
    @driver.find_element(css: "form#resource_form button[type='submit']").click

    @driver.find_element(:link, 'Close Record').click

    extent_headings = @driver.blocking_find_elements(css: '#resource_extents_ .panel-heading')

    expect(extent_headings.length).to eq 1
    assert(5) { expect(extent_headings[0].text).to match /^\d.*/ }
  end

  # Archival Object Trees
  it 'can populate the archival object tree' do
    @driver.get_edit_page(@resource)

    @driver.find_element(:link, 'Add Child').click

    @driver.clear_and_send_keys([:id, 'archival_object_title_'], 'Lost mail')
    @driver.find_element(:id, 'archival_object_level_').select_option('item')

    @driver.click_and_wait_until_gone(id: 'createPlusOne')

    %w[January February December]. each do |month|
      # Wait for the new empty form to be populated.  There's a tricky race
      # condition here that I can't quite track down, so here's my blunt
      # instrument fix.
      @driver.find_element(:xpath, "//textarea[@id='archival_object_title_' and not(text())]")

      @driver.clear_and_send_keys([:id, 'archival_object_title_'], month)
      @driver.find_element(:id, 'archival_object_level_').select_option('item')

      old_element = @driver.find_element(:id, 'archival_object_title_')
      @driver.click_and_wait_until_gone(id: 'createPlusOne')
    end

    elements = tree_nodes_at_level(1).map { |li| li.text.strip }

    %w[January February December].each do |month|
      expect(elements.any? { |elt| elt =~ /#{month}/ }).to be_truthy
    end

    @driver.click_and_wait_until_gone(:css, 'a.btn.btn-cancel')
  end

  it 'can cancel edits to Archival Objects' do
    ao_id = @archival_object.uri.sub(%r{.*/}, '')
    @driver.get("#{$frontend}#{@resource.uri.sub(%r{/repositories/\d+}, '')}/edit#tree::archival_object_#{ao_id}")

    # sanity check..
    tree_click(tree_node(@archival_object))
    pane_resize_handle = @driver.find_element(css: '.ui-resizable-handle.ui-resizable-s')

    @driver.clear_and_send_keys([:id, 'archival_object_title_'], 'unimportant change')

    tree_click(tree_node(@resource))
    @driver.click_and_wait_until_gone(:id, 'dismissChangesButton')
  end

  it 'reports warnings when updating an Archival Object with invalid data' do
    ao_id = @archival_object.uri.sub(%r{.*/}, '')
    @driver.get("#{$frontend}#{@resource.uri.sub(%r{/repositories/\d+}, '')}/edit#tree::archival_object_#{ao_id}")

    # Wait for the form to load in
    @driver.find_element(css: "form#archival_object_form button[type='submit']")

    @driver.find_element(:id, 'archival_object_level_').select_option('item')
    @driver.clear_and_send_keys([:id, 'archival_object_title_'], '')
    @driver.click_and_wait_until_gone(css: "form .record-pane button[type='submit']")

    expect do
      @driver.find_element_with_text('//div[contains(@class, "error")]', /Title - must not be an empty string/)
    end.not_to raise_error
    tree_click(tree_node(@resource))
    @driver.click_and_wait_until_gone(:id, 'dismissChangesButton')
  end

  it 'can update an existing Archival Object' do
    @driver.get_edit_page(@archival_object)

    # Wait for the form to load in
    @driver.find_element(css: "form#archival_object_form button[type='submit']")

    @driver.clear_and_send_keys([:id, 'archival_object_title_'], 'save this please')
    @driver.find_element(css: "form .record-pane button[type='submit']").click
    @driver.wait_for_ajax
    assert(5) { expect(@driver.find_element(:css, 'h2').text).to eq('save this please Archival Object') }
    assert(5) { expect(@driver.find_element(css: 'div.alert.alert-success').text).to eq('Archival Object save this please updated') }
    @driver.clear_and_send_keys([:id, 'archival_object_title_'], @archival_object.title)
    @driver.click_and_wait_until_gone(css: "form .save-changes button[type='submit']")
  end

  it 'can add a assign, remove, and reassign a Subject to an archival object' do
    @driver.get_edit_page(@archival_object)

    @driver.find_element(css: '#archival_object_subjects_ .subrecord-form-heading .btn:not(.show-all)').click
    sleep(10)

    @driver.find_element(css: '#archival_object_subjects_ .linker-wrapper a.btn').click

    @driver.find_element(css: '#archival_object_subjects_ a.linker-create-btn').click

    @driver.find_element(:css, '.modal #subject_terms_ .btn:not(.show-all)').click

    @driver.clear_and_send_keys([id: 'subject_terms__0__term_'], "#{$$}TestTerm123")
    @driver.clear_and_send_keys([id: 'subject_terms__1__term_'], "#{$$}FooTerm456")
    @driver.find_element(id: 'subject_source_').select_option('local')

    @driver.find_element(:id, 'createAndLinkButton').click

    # remove the linked Subject but find it using typeahead and re-add it" do
    @driver.find_element(:css, '.token-input-delete-token').click

    # search for the created subject
    assert(5) do
      run_index_round
      @driver.clear_and_send_keys([:id, 'token-input-archival_object_subjects__0__ref_'], "#{$$}TestTerm123")
      @driver.find_element(:css, 'li.token-input-dropdown-item2').click
    end

    @driver.click_and_wait_until_gone(:css, "form#archival_object_form button[type='submit']")

    # so the subject is here now
    assert(5) { expect(@driver.find_element(:css, '#archival_object_subjects_ ul.token-input-list').text).to match(/#{$$}FooTerm456/) }
  end

  it 'can view a read only Archival Object' do
    @driver.get_edit_page(@archival_object)

    @driver.find_element(:link, 'Close Record').click

    assert(5) { expect(@driver.find_element(:css, '.record-pane h2').text).to eq("#{@archival_object.title} Archival Object") }
  end

  xit 'exports and downloads the resource to xml' do
    @driver.get_view_page(@resource)

    @driver.find_element(:link, 'Export').click
    response = @driver.find_element(:link, 'Download EAD').click
    @driver.wait_for_ajax
    assert(5) { expect(Dir.glob(File.join(Dir.tmpdir, '*_ead.xml')).length).to eq(1) }
    system("rm -f #{File.join(Dir.tmpdir, '*_ead.xml')}")
  end

  # # this is a pretty weak test, but pdf functionality has been move down to
  # jobs, where it's tested..
  it 'displays a link for downloading pdf' do
    @driver.get("#{$frontend}#{@resource.uri.sub(%r{/repositories/\d+}, '')}")

    @driver.find_element(:link, 'Export').click
    expect do
      @driver.find_element_with_text(:link, /Print Resource to PDF/)
    end
  end

end
