# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Digital Objects', js: true do
  let(:admin_user) { BackendClientMethods::ASpaceUser.new('admin', 'admin') }

  before(:all) do
    @repository = create(:repo, repo_code: "digital_objects_test_#{Time.now.to_i}")
    set_repo @repository

    @user = create_user(@repository => ['repository-archivists'])
  end

  before(:each) do
    login_user(@user)
    select_repository(@repository)
  end

  it 'reports errors and warnings when creating an invalid Digital Object' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Digital Object'
    element = find('h2')
    expect(element.text).to eq 'New Digital Object Digital Object'

    # Click on save
    find('button', text: 'Save Digital Object', match: :first).click

    expect(page).to have_selector('h2', visible: true, text: "New Digital Object Digital Object")

    element = find('.alert.alert-danger.with-hide-alert')
    expect(element.text).to eq "Title - Property is required but was missing\nIdentifier - Property is required but was missing"
  end

  it 'can handle multiple file versions and file system and network path types' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Digital Object'
    element = find('h2')
    expect(element.text).to eq 'New Digital Object Digital Object'

    fill_in 'digital_object_title_', with: "Digital Object Title #{now}"
    fill_in 'digital_object_digital_object_id_', with: "Digital Object Identifier #{now}"
    select 'Mixed Materials', from: 'digital_object_digital_object_type_'

    find('button', text: 'Add File Version', match: :first).click
    fill_in 'digital_object_file_versions__0__file_uri_', with: '/root/top_secret.txt'
    element = find('#digital_object_file_versions__0__file_size_bytes_')
    element.fill_in with: '100'

    find('button', text: 'Add File Version', match: :first).click
    fill_in 'digital_object_file_versions__1__file_uri_', with: 'C:\Program Files\windows.exe'
    element = find('#digital_object_file_versions__1__file_size_bytes_')
    element.fill_in with: '200'

    find('button', text: 'Add File Version', match: :first).click
    fill_in 'digital_object_file_versions__2__file_uri_', with: '\\\\NetworkPath\Network\location.bat'
    element = find('#digital_object_file_versions__2__file_size_bytes_')
    element.fill_in with: '300'

    # Click on save
    element = find('button', text: 'Save Digital Object', match: :first).click

    expect(page).to have_selector('h2', visible: true, text: "Digital Object Title #{now} Digital Object")

    expect(page).to have_css('.alert.alert-success.with-hide-alert', text: "Digital Object Digital Object Title #{now} created")

    click_on 'Close Record'

    element = find('h2')
    expect(element.text).to eq "Digital Object Title #{now} Digital Object"
    expect(page).to have_css 'h3', text: 'File Versions'
    elements = all('#digital_object_file_versions__accordion .row')
    expect(elements.length).to eq 3

    expect(elements[0]).to have_text '/root/top_secret.txt'
    expect(elements[1]).to have_text 'C:\Program Files\windows.exe'
    expect(elements[2]).to have_text '\\\\NetworkPath\Network\location.bat'
  end

  it "make representative is disabled unless published is checked, and vice versa" do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Digital Object'
    element = find('h2')
    expect(element.text).to eq 'New Digital Object Digital Object'

    fill_in 'digital_object_title_', with: "Digital Object Title #{now}"
    fill_in 'digital_object_digital_object_id_', with: "Digital Object Identifier #{now}"
    select 'Mixed Materials', from: 'digital_object_digital_object_type_'

    click_on 'Add File Version'
    fill_in 'digital_object_file_versions__0__file_uri_', with: "File Version URI #{now}"
    element = find('#digital_object_file_versions__0__file_size_bytes_')
    element.fill_in with: '100'

    # Click on save
    element = find('button', text: 'Save Digital Object', match: :first).click

    expect(page).to have_selector('h2', visible: true, text: "Digital Object Title #{now} Digital Object")

    expect(page).to have_css('.alert.alert-success.with-hide-alert', text: "Digital Object Digital Object Title #{now} created")

    within '#digital_object_file_versions__0_' do
      expect(page).to have_button('Make Representative', disabled: true)
      find('#digital_object_file_versions__0__publish_').click
      expect(page).to have_button('Make Representative', disabled: false)
    end
  end

  it 'reports errors if adding a child with no title to a Digital Object' do
    now = Time.now.to_i
    digital_object = create(:digital_object, title: "Digital Object Title #{now}")
    run_index_round

    visit "digital_objects/#{digital_object.id}/edit"

    expect(page).to have_selector('h2', visible: true, text: "#{digital_object.title} Digital Object")

    click_on 'Add Child'

    wait_for_ajax

    element = find('h2')
    expect(element.text).to eq "Digital Object Component Digital Object Component"

    fill_in 'digital_object_component_component_id_', with: "Digital Object Identifier #{now}"

    find('#createPlusOne').click

    element = find('.alert.alert-danger.with-hide-alert')
    expect(element.text).to eq "Dates - you must provide a Label, Title or Date\nTitle - you must provide a Label, Title or Date\nLabel - you must provide a Label, Title or Date"
  end

  it 'can populate the digital object component tree' do
    now = Time.now.to_i
    digital_object = create(:digital_object, title: "Digital Object Title #{now}", dates: [], extents: [])
    run_index_round

    visit "digital_objects/#{digital_object.id}/edit"

    expect(page).to have_selector('h2', visible: true, text: "#{digital_object.title} Digital Object")

    click_on 'Add Child'

    fill_in 'digital_object_component_component_id_', with: "Child 1 #{now}"
    fill_in 'digital_object_component_title_', with: "Child 1 #{now}"

    find('#createPlusOne').click
    wait_for_ajax

    expect(page).to have_selector('h2', visible: true, text: "Digital Object Component Digital Object Component")
    expect(page).to have_content "Digital Object Component Child 1 #{now} created on Digital Object Digital Object Title #{now}"

    fill_in 'digital_object_component_component_id_', with: "Child 2 #{now}"
    fill_in 'digital_object_component_title_', with: "Child 2 #{now}"

    find('#createPlusOne').click
    wait_for_ajax

    expect(page).to have_selector('h2', visible: true, text: "Digital Object Component Digital Object Component")
    expect(page).to have_content "Digital Object Component Child 2 #{now} created on Digital Object Digital Object Title #{now}"

    fill_in 'digital_object_component_component_id_', with: "Child 3 #{now}"
    fill_in 'digital_object_component_title_', with: "Child 3 #{now}"

    # Click on save
    find('button', text: 'Save Digital Object', match: :first).click

    expect(page).to have_selector('h2', visible: true, text: "Digital Object Component Digital Object Component")
    expect(page).to have_content "Digital Object Component Child 3 #{now} created on Digital Object Digital Object Title #{now}"

    elements = all('.largetree-node.indent-level-1')
    expect(elements.length).to eq 3
    expect(elements[0]).to have_text "Child 1 #{now}"
    expect(elements[1]).to have_text "Child 2 #{now}"
    expect(elements[2]).to have_text "Child 3 #{now}"
  end

  it 'can drag and drop reorder a Digital Object' do
    now = Time.now.to_i
    digital_object = create(:digital_object, title: "Digital Object Title #{now}")
    digital_object_child = create(:digital_object_component, title: "Child #{now}", digital_object: { ref: digital_object.uri })
    run_index_round

    visit "digital_objects/#{digital_object.id}/edit"

    expect(page).to have_selector('h2', visible: true, text: "#{digital_object.title} Digital Object")

    click_on "Child #{now}"

    click_on 'Add Child'

    wait_for_ajax

    fill_in 'digital_object_component_title_', with: "Sub-Child #{now}"
    fill_in 'digital_object_component_component_id_', with: "Sub-Child #{now}"

    # Click on save
    find('button', text: 'Save Digital Object', match: :first).click

    wait_for_ajax

    expect(page).to have_css('.alert.alert-success.with-hide-alert', text: "Digital Object Component Sub-Child #{now} created as child of Child #{now} on Digital Object Digital Object Title #{now}")

    find('button.tree-resize-toggle').click

    root_node = find("#digital_object_#{digital_object.id}")
    child_node = find("#digital_object_component_#{digital_object_child.id}.table-row.largetree-node.indent-level-1")
    expect(child_node).to have_text "Child #{now}"
    sub_child_node = find('.table-row.largetree-node.indent-level-2.current')
    expect(sub_child_node).to have_text "Sub-Child #{now}"

    click_on 'Enable Reorder Mode'
    sub_child_node.drag_to root_node

    root_node = find("#digital_object_#{digital_object.id}")
    child_node = find("#digital_object_component_#{digital_object_child.id}.table-row.largetree-node.indent-level-1")
    expect(child_node).to have_text "Child #{now}"
    sub_child_node = find('.table-row.largetree-node.indent-level-1.current')
    expect(sub_child_node).to have_text "Sub-Child #{now}"

    visit "digital_objects/#{digital_object.id}/edit"

    expect(page).to have_selector('h2', visible: true, text: "#{digital_object.title} Digital Object")

    root_node = find("#digital_object_#{digital_object.id}")
    expect(root_node).to have_text "Digital Object Title #{now}"

    elements = all('.table-row.largetree-node.indent-level-1')
    expect(elements.length).to eq 2
    expect(elements[0]).to have_text "Sub-Child #{now}"
    expect(elements[1]).to have_text "Child #{now}"
  end

  it 'can link a classification to digital object' do
    now = Time.now.to_i
    digital_object = create(:digital_object, title: "Digital Object Title #{now}", dates: [], extents: [])
    classification = create(:classification)
    run_index_round

    visit "digital_objects/#{digital_object.id}/edit"

    expect(page).to have_selector('h2', visible: true, text: "#{digital_object.title} Digital Object")

    click_on 'Add Classification'

    wait_for_ajax

    fill_in 'token-input-digital_object_classifications__0__ref_', with: classification.title
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    # Click on save
    find('button', text: 'Save Digital Object', match: :first).click
    expect(page).to have_css('.alert.alert-success.with-hide-alert', text: "Digital Object Digital Object Title #{now} updated")

    element = find('#digital_object_classifications__0_')
    expect(element).to have_text classification.title
  end

  it 'provides alt text for Digital Object file version images based on caption or title' do
    now = Time.now.to_i
    digital_object = create(
      :digital_object,
      title: "Digital Object Title #{now}",
      file_versions: [
        {
          file_uri: "File URI 1 #{now}",
          file_format_name: "jpeg",
          caption: "File Format Caption 1 #{now}"
        },
        {
          file_uri: "File URI 2 #{now}",
          file_format_name: "jpeg",
          caption: "File Format Caption 2 #{now}"
        }
      ]
    )

    run_index_round

    visit "digital_objects/#{digital_object.id}"

    expect(page).to have_selector('h2', visible: true, text: "#{digital_object.title} Digital Object")

    expand_elements = all('#digital_object_file_versions__accordion .glyphicon')
    expect(expand_elements.length).to eq 2

    expand_elements[0].click

    wait_for_ajax

    element = find('#digital_object_file_versions__file_version_0')
    expect(element).to have_text "File Format Caption 1 #{now}"

    expand_elements[1].click

    element = find('#digital_object_file_versions__file_version_1')
    expect(element).to have_text "File Format Caption 2 #{now}"
  end

  it 'provides alt text for Digital Object Component file version images based on caption or title' do
    now = Time.now.to_i
    digital_object = create(
      :digital_object,
      title: "Digital Object Title #{now}",
      file_versions: [
        {
          file_uri: "File URI 1 #{now}",
          file_format_name: "jpeg",
          caption: "File Format Caption 1 #{now}"
        },
        {
          file_uri: "File URI 2 #{now}",
          file_format_name: "jpeg",
          caption: "File Format Caption 2 #{now}"
        }
      ]
    )

    digital_object_component = create(
      :digital_object_component,
      digital_object: { ref: digital_object.uri },
      title: "Digital Object Component Title #{now}",
      file_versions: [
        {
          file_uri: "File URI 1 #{now}",
          file_format_name: "jpeg",
          caption: "File Format Caption 1 #{now}"
        },
        {
          file_uri: "File URI 2 #{now}",
          file_format_name: "jpeg",
          caption: "File Format Caption 2 #{now}"
        }
      ]
    )

    run_index_round

    visit "digital_objects/#{digital_object.id}/#tree::digital_object_component_#{digital_object_component.id}"

    expect(page).to have_selector('h2', visible: true, text: "#{digital_object_component.title} Digital Object Component")

    expand_elements = all('#digital_object_component_file_versions_ .glyphicon')
    expect(expand_elements.length).to eq 2

    expand_elements[0].click
    element = find('#digital_object_component_file_versions__file_version_0')
    expect(element).to have_text "File Format Caption 1 #{now}"

    expand_elements[1].click
    element = find('#digital_object_component_file_versions__file_version_1')
    expect(element).to have_text "File Format Caption 2 #{now}"
  end

  describe 'title field mixed content validation' do
    let(:digital_object) { create(:digital_object, title: 'Digital Object') }

    context 'for a parent Digital Object' do
      let(:edit_path) { "digital_objects/#{digital_object.id}/edit" }
      let(:input_field_id) { 'digital_object_title_' }

      it_behaves_like 'validating mixed content'
    end

    context 'for a child Digital Object Component' do
      let(:digital_object_component) { create(:digital_object_component, title: 'Digital Object Component', digital_object: { ref: digital_object.uri }) }
      let(:edit_path) { "digital_objects/#{digital_object.id}/edit#tree::digital_object_component_#{digital_object_component.id}" }
      let(:input_field_id) { 'digital_object_component_title_' }

      it_behaves_like 'validating mixed content'
    end
  end

  context 'index view' do
    describe 'results table' do
      let(:now) { Time.now.to_i }
      let(:record_type) { 'digital_object' }
      let(:browse_path) { '/digital_objects' }
      let(:record_1) do
        create(:digital_object,
          title: "Digital Object 1 #{now}",
          digital_object_id: "2",
          level: 'image',
          digital_object_type: 'mixed_materials',
          publish: true
        )
      end
      let(:record_2) do
        create(:digital_object,
          title: "Digital Object 2 #{now}",
          digital_object_id: "1",
          level: 'collection',
          digital_object_type: 'text',
          publish: false
        )
      end
      let(:initial_sort) { [record_1.title, record_2.title] }

      describe 'sorting' do
        include_context 'results table setup'

        let(:default_sort_key) { 'title_sort' }
        let(:additional_browse_columns) do
          {
            2 => 'Digital Object ID',
            3 => 'Digital Object Type',
            4 => 'Level',
            # 5 => 'Published',
            6 => 'URI'
          }
        end
        let(:column_headers) do
          {
            'Title' => 'title_sort',
            'Digital Object ID' => 'digital_object_id',
            'Digital Object Type' => 'digital_object_type',
            'Level' => 'level',
            # 'Published' => 'publish',
            'URI' => 'uri'
          }
        end
        let(:sort_expectations) do
          {
            'title_sort' => {
              asc: [record_1.title, record_2.title],
              desc: [record_2.title, record_1.title]
            },
            'digital_object_id' => {
              asc: [record_2.title, record_1.title],
              desc: [record_1.title, record_2.title]
            },
            'digital_object_type' => {
              asc: [record_1.title, record_2.title],
              desc: [record_2.title, record_1.title]
            },
            'level' => {
              asc: [record_2.title, record_1.title],
              desc: [record_1.title, record_2.title]
            },
            # 'publish' => {
            #   asc: [record_2.title, record_1.title],
            #   desc: [record_1.title, record_2.title]
            # },
            'uri' => uri_id_as_string_sort_expectations([record_1, record_2], ->(r) { r.title })
          }
        end

        # Optional third record for secondary sort tests
        # Uses same level ("collection") and digital_object_type ("text") as record_2 to create ties
        let(:record_3) do
          create(:digital_object,
            title: "Digital Object 3 #{now}",
            digital_object_id: "3",
            level: 'collection',
            digital_object_type: 'text',
            publish: false
          )
        end

        # Secondary sort test cases
        let(:secondary_sort_cases) do
          [
            {
              # Case 1: primary title_sort asc, secondary level asc - no-op since titles are unique
              primary_key:   'title_sort',
              primary_dir:   :asc,
              secondary_key: 'level',
              secondary_dir: :asc,
              expected_after_primary: [
                record_1.title,
                record_2.title,
                record_3.title
              ],
              expected_after_both: [
                record_1.title,
                record_2.title,
                record_3.title
              ]
            },
            {
              # Case 2: primary level asc, secondary title_sort desc - secondary changes order
              # record_2 and record_3 both have level="collection", so they tie.
              # After primary-only: "collection" < "image" alphabetically, so collection records first.
              #   Solr tie-breaks by ID, so record_2 before record_3.
              # After secondary (title_sort desc): "Digital Object 3" > "Digital Object 2", so record_3 moves first.
              primary_key:   'level',
              primary_dir:   :asc,
              secondary_key: 'title_sort',
              secondary_dir: :desc,
              expected_after_primary: [
                record_2.title,
                record_3.title,
                record_1.title
              ],
              expected_after_both: [
                record_3.title,
                record_2.title,
                record_1.title
              ]
            },
            {
              # Case 3: primary digital_object_id asc, secondary digital_object_type asc - no-op since IDs are unique
              primary_key:   'digital_object_id',
              primary_dir:   :asc,
              secondary_key: 'digital_object_type',
              secondary_dir: :asc,
              expected_after_primary: [
                record_2.title,
                record_1.title,
                record_3.title
              ],
              expected_after_both: [
                record_2.title,
                record_1.title,
                record_3.title
              ]
            }
          ]
        end

        it_behaves_like 'results table sorting'
      end

      # Skipped due to ANW-2543 publish issue when running specs
      xdescribe 'boolean columns' do
        include_context 'results table setup'

        let(:additional_browse_columns) do
          {
            5 => 'Published'
          }
        end
        let(:boolean_column_expectations) do
          {
            'publish' => %w[True False]
          }
        end

        it_behaves_like 'results table boolean columns'
      end
    end
  end

  describe 'Linked Agents is_primary behavior' do
    let(:agent) { create(:agent_person) }

    before do
      set_repo @repository
      login_admin
      select_repository(@repository)
    end

    context 'for a parent Digital Object' do
      let(:record_type) { 'digital_object' }
      let(:record) do
        create(
          :digital_object,
          title: "Digital Object Title #{Time.now.to_i}",
          linked_agents: [
            { ref: agent.uri, role: 'creator' }
          ],
          rights_statements: [
            build(
              :json_rights_statement,
              rights_type: 'copyright',
              status: 'copyrighted',
              jurisdiction: 'AU',
              start_date: Time.now.strftime('%Y-%m-%d'),
              linked_agents: [
                { ref: agent.uri, role: 'rights_holder' }
              ]
            )
          ]
        )
      end
      let(:edit_path) { "/digital_objects/#{record.id}/edit" }

      it_behaves_like 'supporting is_primary on top-level linked agents'
      it_behaves_like 'not supporting is_primary on rights statement linked agents'
    end

    context 'for child Digital Object Components' do
      let(:record_type) { 'digital_object_component' }
      let(:parent_digital_object) do
        create(
          :digital_object,
          title: "Digital Object Title #{Time.now.to_i}"
        )
      end
      let(:record) do
        create(
          :digital_object_component,
          digital_object: { ref: parent_digital_object.uri },
          title: "Digital Object Component Title #{Time.now.to_i}",
          linked_agents: [
            { ref: agent.uri, role: 'creator' }
          ],
          rights_statements: [
            build(
              :json_rights_statement,
              rights_type: 'copyright',
              status: 'copyrighted',
              jurisdiction: 'AU',
              start_date: Time.now.strftime('%Y-%m-%d'),
              linked_agents: [
                { ref: agent.uri, role: 'rights_holder' }
              ]
            )
          ]
        )
      end
      let(:edit_path) { "/digital_objects/#{parent_digital_object.id}/edit#tree::digital_object_component_#{record.id}" }

      it_behaves_like 'supporting is_primary on top-level linked agents'
      it_behaves_like 'not supporting is_primary on rights statement linked agents'
    end
  end
end
