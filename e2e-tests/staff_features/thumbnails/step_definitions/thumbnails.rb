# frozen_string_literal: true

THUMBNAIL_FILES = {
  'an image' => { uri: "#{WIREMOCK_URL}/thumbnails/image.jpg", format: 'JPEG File Interchange Format' },
  'a broken image' => { uri: "#{WIREMOCK_URL}/thumbnails/missing.jpg", format: 'JPEG File Interchange Format' },
  'a document' => { uri: 'http://example.com/thumbnails/document.pdf', format: 'Portable Document Format' },
  'another document' => { uri: 'http://example.com/thumbnails/another-document.pdf', format: 'Portable Document Format' },
  'a third document' => { uri: 'http://example.com/thumbnails/third-document.pdf', format: 'Portable Document Format' }
}.freeze

THUMBNAIL_SELECTORS = {
  staff: {
    thumbnail: '.record-pane .digital-object-thumbnail',
    icon: '.digital-object-thumbnail-icon',
    fallback_icon: '.digital-object-thumbnail-fallback',
    caption: '.digital-object-thumbnail-caption'
  },
  public: {
    thumbnail: '.pui-thumbnail',
    icon: '.pui-thumbnail-icon',
    fallback_icon: '.pui-thumbnail-fallback',
    caption: '.pui-thumbnail-caption'
  }
}.freeze

# Generic icon classes by Digital Object Type
THUMBNAIL_TYPE_ICONS = {
  'Moving Image' => { staff: 'fa-file-video', public: 'fa-file-video-o' },
  'Sound Recording' => { staff: 'fa-file-audio', public: 'fa-file-audio-o' },
  'Sound Recording (Musical)' => { staff: 'fa-file-audio', public: 'fa-file-audio-o' },
  'Sound Recording (Non-musical)' => { staff: 'fa-file-audio', public: 'fa-file-audio-o' },
  'Still Image' => { staff: 'fa-file-image', public: 'fa-file-image-o' },
  'Text' => { staff: 'fa-file-lines', public: 'fa-file-text-o' },
  # every other type shows the plain file icon
  'Cartographic' => { staff: 'fa-file', public: 'fa-file-o' },
  'Mixed Materials' => { staff: 'fa-file', public: 'fa-file-o' },
  'Notated Music' => { staff: 'fa-file', public: 'fa-file-o' },
  'Software, Multimedia' => { staff: 'fa-file', public: 'fa-file-o' }
}.freeze

THUMBNAIL_BROWSE_COLUMN_TYPES = {
  'Digital Object' => 'digital_object',
  'Digital Object Component' => 'digital_object_component',
  'Accession' => 'accession',
  'Resource' => 'resource',
  'Archival Object' => 'archival_object',
  'Search' => 'multi'
}.freeze

THUMBNAIL_PREFERENCES_PAGES = {
  'Global Preferences' => '/preferences/0/edit?global=true',
  'Repository Preferences' => '/preferences/0/edit',
  'Default Repository Preferences' => '/preferences/0/edit?repo=true'
}.freeze

Before do
  @thumbnail_records = {}
end

# Restore the browse column changed by the "selects Thumbnail for a browse column" step
After('@thumbnail_column_preference') do
  next unless @thumbnail_changed_browse_column

  visit "#{STAFF_URL}#{THUMBNAIL_PREFERENCES_PAGES.fetch('Repository Preferences')}"
  find("##{@thumbnail_changed_browse_column} option[value='']").select_option
  find('button[type="submit"]', text: 'Save', match: :first).click
end

def thumbnail_record(name)
  @thumbnail_records.fetch(name) { raise "No record named '#{name}' was created in this scenario" }
end

def thumbnail_file(name)
  THUMBNAIL_FILES.fetch(name) { raise "Unknown file '#{name}', use one of: #{THUMBNAIL_FILES.keys.join(', ')}" }
end

def thumbnail_selector(element)
  THUMBNAIL_SELECTORS.fetch(@thumbnail_interface).fetch(element)
end

def thumbnail_staff_path(record)
  case record[:type]
  when 'digital_object' then "/digital_objects/#{record[:id]}"
  when 'digital_object_component' then "/digital_objects/#{record[:parent_id]}#tree::digital_object_component_#{record[:id]}"
  when 'accession' then "/accessions/#{record[:id]}"
  when 'resource' then "/resources/#{record[:id]}"
  when 'archival_object' then "/resources/#{record[:parent_id]}#tree::archival_object_#{record[:id]}"
  else raise "No staff page for record type '#{record[:type]}'"
  end
end

def within_first_thumbnail(&block)
  retry_with_reload do
    within(first(thumbnail_selector(:thumbnail), minimum: 1), &block)
  end
end

def thumbnail_add_file_versions(form_prefix, file_versions)
  file_versions.each do |row|
    within add_file_version(form_prefix) do
      file = thumbnail_file(row.fetch('File'))

      fill_in 'File URI', with: file[:uri]
      select file[:format], from: 'File Format Name'
      row.fetch('Published') == 'yes' ? check('Publish?') : uncheck('Publish?')
      fill_in 'Caption', with: row['Caption'] unless row['Caption'].to_s.empty?
      click_on "Make #{row['Marked as']}" unless row['Marked as'].to_s.empty?
    end
  end
end

def thumbnail_create_digital_object(name, file_versions, digital_object_type: nil)
  title = "#{name} #{@uuid}"

  visit "#{STAFF_URL}/digital_objects/new"
  fill_in 'digital_object_digital_object_id_', with: "#{name} Identifier #{@uuid}"
  fill_in 'digital_object_title_', with: title
  select digital_object_type, from: 'digital_object_digital_object_type_' if digital_object_type
  check 'digital_object_publish_'

  thumbnail_add_file_versions('digital_object', file_versions)

  click_on 'Save'
  expect(page).to have_css('.alert.alert-success.with-hide-alert', text: "Digital Object #{title} created")

  @thumbnail_records[name] = { type: 'digital_object', id: extract_created_record_id('Digital Object'), title: }
end

# Links the named Digital Object as a new instance of the record in the open edit form
def thumbnail_add_digital_object_instance(form_prefix, digital_object_name, representative:)
  digital_object = thumbnail_record(digital_object_name)

  within "##{form_prefix}_instances_" do
    find('button', text: 'Add Digital Object', match: :first).click
  end

  instance = all("##{form_prefix}_instances_ .subrecord-form-list > li").last
  token_input = instance.find("input[id^='token-input-'][id$='digital_object__ref_']")
  select_in_linker(token_input, digital_object[:title])

  within(instance) { click_on 'Make Representative' } if representative
end

def thumbnail_visit(record)
  if @thumbnail_interface == :staff
    visit "#{STAFF_URL}#{thumbnail_staff_path(record)}"
    wait_for_ajax
    expect(page).to have_css('.record-pane h2', text: record[:title])
  else
    # The record only appears in the public interface once the indexer has picked it up
    visit "#{PUBLIC_URL}#{record_uri(record[:type], record[:id])}"
    retry_with_reload { expect(page).to have_text(record[:title], wait: 5) }
  end
end

# Records

Given 'a Digital Object {string} has been created with the following File Versions' do |name, file_versions|
  thumbnail_create_digital_object(name, file_versions.hashes)
end

Given 'a Digital Object {string} of type {string} has been created with the following File Versions' do |name, digital_object_type, file_versions|
  thumbnail_create_digital_object(name, file_versions.hashes, digital_object_type:)
end

Given 'a Digital Object {string} has been created without File Versions' do |name|
  thumbnail_create_digital_object(name, [])
end

Given 'the Digital Object {string} has a Digital Object Component {string} with the following File Versions' do |parent_name, name, file_versions|
  thumbnail_create_digital_object_component(parent_name, name, file_versions.hashes, title: "#{name} #{@uuid}")
end

Given 'the Digital Object {string} has a Digital Object Component with Label {string}, the date {string} and no Title with the following File Versions' do |parent_name, name, date, file_versions|
  thumbnail_create_digital_object_component(parent_name, name, file_versions.hashes, title: nil, date:)
end

def thumbnail_create_digital_object_component(parent_name, name, file_versions, title:, date: nil)
  parent = thumbnail_record(parent_name)
  label = "#{name} #{@uuid}"

  visit "#{STAFF_URL}/digital_objects/#{parent[:id]}/edit"
  wait_for_ajax
  # Add Child is a no-op until the tree has loaded its current node
  wait_for_infinite_tree_ready_for_rde

  within('#infinite-tree-toolbar') { click_on 'Add Child' }
  wait_for_infinite_tree_inline_new_form(form_prefix: 'digital_object_component')

  fill_in 'digital_object_component_label_', with: label
  fill_in 'digital_object_component_title_', with: title if title
  check 'digital_object_component_publish_'

  if date
    within('#digital_object_component_dates_') { click_on 'Add Date' }
    select 'Single', from: 'digital_object_component_dates__0__date_type_'
    fill_in 'digital_object_component_dates__0__begin_', with: date
  end

  thumbnail_add_file_versions('digital_object_component', file_versions)

  find('button', text: 'Save Digital Object Component', match: :first).click
  # the message names the component by its title, if it has one
  expect(page).to have_text "Digital Object Component #{"#{title} " if title}created on Digital Object #{parent[:title]}"

  @thumbnail_records[name] = {
    type: 'digital_object_component',
    id: extract_created_record_id('Digital Object Component'),
    parent_id: parent[:id],
    # without a title, the label serves as the title of a Digital Object Component
    title: title || label,
    label:,
    date:
  }
end

Given 'an Accession {string} has been created with the Digital Object {string} as its representative instance' do |name, digital_object_name|
  thumbnail_create_accession(name, digital_object_name, representative: true)
end

Given 'an Accession {string} has been created with the Digital Object {string} as an instance that is not representative' do |name, digital_object_name|
  thumbnail_create_accession(name, digital_object_name, representative: false)
end

def thumbnail_create_accession(name, digital_object_name, representative:)
  title = "#{name} #{@uuid}"

  visit "#{STAFF_URL}/accessions/new"
  fill_in 'accession_id_0_', with: "#{name} #{@uuid}"
  fill_in 'Title', with: title
  fill_in 'Accession Date', with: ORIGINAL_ACCESSION_DATE
  check 'accession_publish_'

  thumbnail_add_digital_object_instance('accession', digital_object_name, representative:)

  click_on 'Save'
  expect(page).to have_text "Accession #{title} created"

  @thumbnail_records[name] = { type: 'accession', id: current_url.split('/')[-2], title: }
end

Given 'a Resource {string} has been created' do |name|
  thumbnail_create_resource(name, nil)
end

Given 'a Resource {string} has been created with the Digital Object {string} as its representative instance' do |name, digital_object_name|
  thumbnail_create_resource(name, digital_object_name)
end

def thumbnail_create_resource(name, digital_object_name)
  create_resource(@uuid)

  if digital_object_name
    visit "#{STAFF_URL}/resources/#{@resource_id}/edit"
    wait_for_ajax

    thumbnail_add_digital_object_instance('resource', digital_object_name, representative: true)

    find('button', text: 'Save Resource', match: :first).click
    expect(page).to have_css('.alert.alert-success.with-hide-alert', text: "Resource Resource #{@uuid} updated")
  end

  @thumbnail_records[name] = { type: 'resource', id: @resource_id, title: "Resource #{@uuid}" }
end

Given 'the Resource {string} has an Archival Object {string} with the Digital Object {string} as its representative instance' do |resource_name, name, digital_object_name|
  resource = thumbnail_record(resource_name)
  title = "#{name} #{@uuid}"

  visit "#{STAFF_URL}/resources/#{resource[:id]}/edit"
  wait_for_ajax
  # Add Child is a no-op until the tree has loaded its current node
  wait_for_infinite_tree_ready_for_rde

  within('#infinite-tree-toolbar') { click_on 'Add Child' }
  wait_for_infinite_tree_inline_new_form(form_prefix: 'archival_object')

  fill_in 'Title', with: title
  select 'File', from: 'Level of Description'
  check 'archival_object_publish_'

  thumbnail_add_digital_object_instance('archival_object', digital_object_name, representative: true)

  find('button', text: 'Save Archival Object', match: :first).click
  expect(page).to have_text "Archival Object #{title} on Resource #{resource[:title]} created"

  @thumbnail_records[name] = {
    type: 'archival_object',
    id: extract_created_record_id('Archival Object'),
    parent_id: resource[:id],
    title:
  }
end

# Viewing

When 'the user views the {string} in the staff interface' do |name|
  @thumbnail_interface = :staff
  thumbnail_visit(thumbnail_record(name))
end

When 'the user views the {string} in the public interface' do |name|
  @thumbnail_interface = :public
  thumbnail_visit(thumbnail_record(name))
end

When 'the user opens the {string} in edit mode' do |name|
  record = thumbnail_record(name)
  visit "#{STAFF_URL}/digital_objects/#{record[:id]}/edit"
  wait_for_ajax
end

When 'the user adds a File Version for {string}' do |file_name|
  within add_file_version('digital_object') do
    fill_in 'File URI', with: thumbnail_file(file_name)[:uri]
  end
end

# Thumbnail assertions

Then 'the thumbnail shows {string}' do |file_name|
  uri = thumbnail_file(file_name)[:uri]

  within_first_thumbnail do
    expect(page).to have_css("img[src='#{uri}']")
    expect(page).not_to have_css(thumbnail_selector(:fallback_icon))
  end
end

Then 'the thumbnail shows the generic icon' do
  within_first_thumbnail do
    expect(page).to have_css(thumbnail_selector(:icon))
    expect(page).not_to have_css('img')
  end
end

Then 'the thumbnail shows the generic icon for a {string} Digital Object' do |digital_object_type|
  icon_class = THUMBNAIL_TYPE_ICONS.fetch(digital_object_type).fetch(@thumbnail_interface)

  within_first_thumbnail do
    expect(page).to have_css("#{thumbnail_selector(:icon)}.#{icon_class}")
    expect(page).not_to have_css('img')
  end
end

Then 'the thumbnail falls back to the generic icon because the browser cannot render {string}' do |file_name|
  uri = thumbnail_file(file_name)[:uri]

  within_first_thumbnail do
    expect(page).to have_css("img[src='#{uri}']", visible: :hidden)
    expect(page).to have_css(thumbnail_selector(:fallback_icon), visible: true)
  end
end

Then 'the thumbnail links to {string}' do |file_name|
  uri = thumbnail_file(file_name)[:uri]

  within_first_thumbnail do
    expect(page).to have_css("a[href='#{uri}']")
  end
end

Then 'the thumbnail links to the Digital Object {string}' do |digital_object_name|
  digital_object = thumbnail_record(digital_object_name)
  digital_object_uri = record_uri(digital_object[:type], digital_object[:id])

  within_first_thumbnail do
    if @thumbnail_interface == :staff
      # staff interface links go through the resolver: /resolve/readonly?uri=<record uri>
      expect_link_with_href(a_string_ending_with("uri=#{digital_object_uri}"))
    else
      expect_link_with_href(a_string_ending_with(digital_object_uri))
    end
  end
end

Then 'the thumbnail has no link' do
  within_first_thumbnail do
    expect(page).not_to have_css('a')
  end
end

Then 'the thumbnail has the caption {string}' do |caption|
  within_first_thumbnail do
    expect(page).to have_css(thumbnail_selector(:caption), exact_text: caption)
  end
end

Then 'the thumbnail caption is the display string of {string}, with its label and date' do |name|
  component = thumbnail_record(name)

  within_first_thumbnail do
    caption = find(thumbnail_selector(:caption)).text
    expect(caption).to include(component[:label])
    expect(caption).to include(component[:date])
  end
end

Then 'the thumbnail caption is the title of {string}' do |name|
  title = thumbnail_record(name)[:title]

  within_first_thumbnail do
    expect(page).to have_css(thumbnail_selector(:caption), text: title)
  end
end

Then 'no thumbnail or generic icon is shown' do
  retry_with_reload do
    expect(page).not_to have_css(thumbnail_selector(:thumbnail))
  end
end

Then 'the public interface offers to browse {int} digital object(s) in the collection' do |count|
  noun = count == 1 ? 'digital object' : 'digital objects'

  within_first_thumbnail do
    expect(page).to have_link("Browse #{count} #{noun} in collection")
  end
end

# File Versions

Then 'the File Version for {string} is not marked as the Display Link' do |file_name|
  uri = thumbnail_file(file_name)[:uri]
  header = find('#digital_object_file_versions_ .card-header', text: uri)

  expect(header).not_to have_css('.badge', text: 'Display Link')
end

Then 'the {string} button of the last File Version is disabled' do |button_text|
  within all('#digital_object_file_versions_ .subrecord-form-list > li').last do
    expect(page).to have_button(button_text, disabled: true)
  end
end

Then 'the {string} button of the last File Version is enabled' do |button_text|
  within all('#digital_object_file_versions_ .subrecord-form-list > li').last do
    expect(page).to have_button(button_text, disabled: false)
  end
end

When 'the user publishes the last File Version' do
  within all('#digital_object_file_versions_ .subrecord-form-list > li').last do
    check 'Publish?'
  end
end

When 'the user unpublishes the last File Version' do
  within all('#digital_object_file_versions_ .subrecord-form-list > li').last do
    uncheck 'Publish?'
  end
end

Then 'the File Versions list lists only the following files' do |files|
  expected = files.raw.flatten.map { |file_name| thumbnail_file(file_name)[:uri] }

  retry_with_reload do
    listed = all('#additional_file_versions_list li[data-additional-file-version] a', visible: :all).map { |link| link[:href] }
    expect(listed).to match_array(expected)
  end
end

Then 'there is no File Versions list' do
  retry_with_reload do
    expect(page).not_to have_css('#additional_file_versions_list', visible: :all)
  end
end

Then 'no link on the page points to {string}' do |file_name|
  uri = thumbnail_file(file_name)[:uri]

  expect(page).not_to have_css("a[href='#{uri}']", visible: :all)
end

# Browse column preferences

When 'the user is on the {string} page' do |preferences_page|
  visit "#{STAFF_URL}#{THUMBNAIL_PREFERENCES_PAGES.fetch(preferences_page)}"
  expect(page).to have_css('#search_browse_columns')
end

Then 'Thumbnail is an option for each {string} browse column but not for its default sort column' do |record_type|
  type = THUMBNAIL_BROWSE_COLUMN_TYPES.fetch(record_type)
  browse_columns = all("select[id^='preference_defaults__#{type}_browse_column_']", visible: :all)

  expect(browse_columns).not_to be_empty
  browse_columns.each do |browse_column|
    expect(browse_column).to have_css('option', exact_text: 'Thumbnail', visible: :all)
  end

  sort_column = find("#preference_defaults__#{type}_sort_column_", visible: :all)
  expect(sort_column).not_to have_css('option', exact_text: 'Thumbnail', visible: :all)
end

When 'the user selects Thumbnail for {string} browse column {int} in the Repository Preferences' do |record_type, column|
  type = THUMBNAIL_BROWSE_COLUMN_TYPES.fetch(record_type)
  select_id = "preference_defaults__#{type}_browse_column_#{column}_"

  visit "#{STAFF_URL}#{THUMBNAIL_PREFERENCES_PAGES.fetch('Repository Preferences')}"
  find("##{select_id}").select 'Thumbnail'
  @thumbnail_changed_browse_column = select_id

  find('button[type="submit"]', text: 'Save', match: :first).click
  expect(page).to have_css('.alert.alert-success.with-hide-alert', text: 'Preferences updated')
end

When 'the user browses the Digital Objects filtered by {string}' do |name|
  title = thumbnail_record(name)[:title]
  @thumbnail_interface = :staff

  visit "#{STAFF_URL}/digital_objects"
  fill_in 'filter-text', with: title
  within('.search-filter') { find('button').click }

  # The browse listing is searched from the index, which may not have the new record yet. The filter
  # is now in the URL, so a reload repeats the search.
  retry_with_reload(attempts: 12) { expect(page).to have_css('#tabledSearchResults tbody tr', text: title, wait: 5) }
end

Then 'the Thumbnail column shows {string} for {string}' do |file_name, name|
  uri = thumbnail_file(file_name)[:uri]
  row = find('#tabledSearchResults tbody tr', text: thumbnail_record(name)[:title])

  expect(page).to have_css('#tabledSearchResults th.thumbnail-column')
  expect(row).to have_css("td.thumbnail-column img[src='#{uri}']")
end
