# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Tree UI', js: true do
  let(:admin_user) { BackendClientMethods::ASpaceUser.new('admin', 'admin') }

  before(:all) do
    @repository = create(:repo, repo_code: "trees_test_#{Time.now.to_i}")

    run_all_indexers
  end

  before (:each) do
    login_user(admin_user)
    select_repository(@repository)

    @now = Time.now.to_i

    @agent = create(:agent_person)
    @accession = create(:accession)
    @subject = create(:subject)
    @digital_object = create(:digital_object, title: "Digital Object Title #{@now}")

    @resource = create(:resource)
    @archival_object_1 = create(:archival_object, title: "Archival Object Title 1 #{@now}", resource: { ref: @resource.uri })
    @archival_object_2 = create(:archival_object, title: "Archival Object Title 2 #{@now}", resource: { ref: @resource.uri })
    @archival_object_3 = create(
      :archival_object,
      resource: { ref: @resource.uri },
      title: "Archival Object Title 3 #{@now}",
      dates: [
        build(:date),
        build(:date)
      ],
      extents: [build(:extent)],
      notes: [
        build(:json_note_multipart),
        build(:json_note_singlepart)
      ],
      external_documents: [
        build(:json_external_document)
      ],
      rights_statements: [
        build(:json_rights_statement)
      ],
      linked_agents: [
        {
          ref: @agent.uri,
          role: 'creator',
          relator: generate(:relator),
          title: generate(:alphanumstr)
        }
      ],
      accession_links: [
        ref: @accession.uri
      ],
      subjects: [
        ref: @subject.uri
      ],
      instances: [
        {
          instance_type: 'digital_object',
          digital_object: { ref: @digital_object.uri }
        }
      ]
    )

    @archival_object_3_child = create(
      :archival_object,
      resource: { ref: @resource.uri },
      parent: { ref: @archival_object_3.uri },
      title: "Archival Object Title 3 Child #{@now}",
    )

    @archival_object_4 = create(:archival_object, title: "Archival Object Title 4 #{@now}", resource: { ref: @resource.uri })
    @archival_object_4.set_suppressed(true)

    run_index_round

    visit "resources/#{@resource.id}/edit"
    expect(page).to have_text @resource.title
  end

  xit 'can add a sibling' do
    expect(all('.largetree-node.indent-level-1').length).to eq(4)

    click_link "Archival Object Title 3 #{@now}"
    click_on 'Add Sibling'

    expect(page).to have_text 'Archival Object'
    expect(page).to have_text 'Basic Information'
    expect(page).to have_css("#archival_object_title_")
    expect(page).to have_css('#archival_object_level_')

    fill_in 'Title', with: "Sibling #{@now}"
    select 'Item', from: 'Level of Description'

    # Click on save
    element = find('button', text: 'Save', match: :first)
    element.click

    expect(page).to have_text "Archival Object Sibling #{@now} on Resource #{@resource.title} created"

    elements = all('.largetree-node.indent-level-1')
    expect(elements.length).to eq(5)

    visit "resources/#{@resource.id}/edit"
    expect(all('.largetree-node.indent-level-1').length).to eq(5)
  end

  context 'when duplicating an archival object' do
    it 'can add a duplicate archival object' do
      click_on 'Auto-Expand All'
      expect(all('.largetree-node.indent-level-1').length).to eq(4)
      expect(all('.largetree-node.indent-level-2').length).to eq(1)

      click_link "Archival Object Title 3 #{@now}"
      click_on 'Add Duplicate'

      wait_for_ajax

      element = find('.alert.alert-success.with-hide-alert')
      expect(element.text).to eq "Archival Object duplicated from #{@archival_object_3.display_string}"

      expect(find('#archival_object_title_').value).to eq @archival_object_3.title
      expect_archival_object_form_to_have_values_from(@archival_object_3)

      element = find('#archival_object_title_')
      element.fill_in with: "[Duplicated] #{@archival_object_3.title}"

      # Click on save
      find('button', text: 'Save', match: :first).click

      wait_for_ajax

      element = find('.alert.alert-success.with-hide-alert')
      expect(element.text).to eq "Archival Object [Duplicated] #{@archival_object_3.title} on Resource #{@resource.title} created"

      expect(find('#archival_object_title_').value).to eq "[Duplicated] #{@archival_object_3.title}"
      expect_archival_object_form_to_have_values_from(@archival_object_3)

      click_on 'Auto-Expand All'
      arhicval_objects_level_1 = all('.largetree-node.indent-level-1')
      expect(arhicval_objects_level_1.length).to eq(5)
      expect(all('.largetree-node.indent-level-2').length).to eq(1)

      # Duplicated archival object is positioned right after it's original
      expect(arhicval_objects_level_1[2]).to have_text @archival_object_3.title
      expect(arhicval_objects_level_1[3]).to have_text "[Duplicated] #{@archival_object_3.title}"
    end

    it 'does not affect the duplicated archival object if the original is deleted' do
      click_on 'Auto-Expand All'
      expect(all('.largetree-node.indent-level-1').length).to eq(4)
      expect(all('.largetree-node.indent-level-2').length).to eq(1)

      click_link "Archival Object Title 3 #{@now}"
      click_on 'Add Duplicate'

      wait_for_ajax

      element = find('.alert.alert-success.with-hide-alert')
      expect(element.text).to eq "Archival Object duplicated from #{@archival_object_3.display_string}"

      expect(find('#archival_object_title_').value).to eq @archival_object_3.title
      expect_archival_object_form_to_have_values_from(@archival_object_3)

      element = find('#archival_object_title_')
      element.fill_in with: "[Duplicated] #{@archival_object_3.title}"

      # Click on save
      find('button', text: 'Save', match: :first).click

      wait_for_ajax

      element = find('.alert.alert-success.with-hide-alert')
      # expect(element.text).to eq "Archival Object [Duplicated] #{@archival_object_3.display_string} on Resource #{@resource.title} created"
      expect(element.text).to eq "Archival Object [Duplicated] #{@archival_object_3.title} on Resource #{@resource.title} created"

      expect(find('#archival_object_title_').value).to eq "[Duplicated] #{@archival_object_3.title}"
      expect_archival_object_form_to_have_values_from(@archival_object_3)

      click_on 'Auto-Expand All'

      arhicval_objects_level_1 = all('.largetree-node.indent-level-1')
      expect(arhicval_objects_level_1.length).to eq(5)
      expect(all('.largetree-node.indent-level-2').length).to eq(1)

      # Duplicated archival object is positioned right after it's original
      expect(arhicval_objects_level_1[2]).to have_text @archival_object_3.title
      expect(arhicval_objects_level_1[3]).to have_text "[Duplicated] #{@archival_object_3.title}"

      link = find('#tree-container a ', text: @archival_object_3.title, match: :first).click
      click_on 'Delete'
      within '#confirmChangesModal' do
        click_on 'Delete'
      end

      click_on "[Duplicated] #{@archival_object_3.title}"
      click_on 'Edit'

      click_on 'Auto-Expand All'
      expect(all('.largetree-node.indent-level-1').length).to eq(4)
      expect(all('.largetree-node.indent-level-2').length).to eq(0)

      # The @archival_object_3 is now deleted, but it can still be referenced in memory for comparison.
      expect(find('#archival_object_title_').value).to eq "[Duplicated] #{@archival_object_3.title}"
      expect_archival_object_form_to_have_values_from(@archival_object_3)
    end

    def expect_archival_object_form_to_have_values_from(archival_object)
      expect(find('#archival_object_component_id_').value).to eq archival_object.component_id
      expect(find('#archival_object_level_').value).to eq archival_object.level
      expect(find('#archival_object_publish_').checked?).to eq archival_object.publish
      expect(find('#archival_object_restrictions_apply_').checked?).to eq archival_object.restrictions_apply

      lang_materials = all('#archival_object_lang_materials_ [data-object-name="lang_material"]')
      expect(lang_materials.length).to eq archival_object.lang_materials.length

      dates = all('#archival_object_dates_ [data-object-name="date"]')
      expect(dates.length).to eq archival_object.dates.length

      extents = all('#archival_object_extents_ [data-object-name="extent"]')
      expect(extents.length).to eq archival_object.extents.length

      agents = all('#archival_object_linked_agents_ [data-object-name="linked_agent"]')
      expect(agents.length).to eq archival_object.linked_agents.length

      accessions = all('#archival_object_accession_links_ [data-object-name="accession_link"]')
      expect(accessions.length).to eq archival_object.accession_links.length

      subjects = all('#archival_object_subjects_ [data-object-name="subject"]')
      expect(subjects.length).to eq archival_object.subjects.length

      notes = all('#notes [data-object-name="note"]')
      expect(notes.length).to eq archival_object.notes.length

      external_documents = all('#archival_object_external_documents_ [data-object-name="external_document"]')
      expect(external_documents.length).to eq archival_object.external_documents.length

      rights_statements = all('#archival_object_rights_statements_ [data-object-name="rights_statement"]')
      expect(rights_statements.length).to eq archival_object.rights_statements.length

      instances = all('#archival_object_instances_ [data-object-name="instance"]')
      expect(instances.length).to eq 0 # instances should not be duplicated
    end
  end

  xit 'can retain location hash when sidebar items are clicked' do
    click_link "Archival Object Title 1 #{@now}"

    url_hash = current_url.split('#').last
    expect(url_hash).to eq("tree::archival_object_#{@archival_object_1.id}")

    find('.sidebar-entry-notes a').click

    url_hash = current_url.split('#').last
    expect(url_hash).to eq("tree::archival_object_#{@archival_object_1.id}")
  end

  it 'shows the suppressed tag only for suppressed records' do
    elements = all('#tree-container > .table.root > .table-row-group > div > .title > a.record-title > span.label.label-info')
    expect(elements.length).to eq(1)

    element = find("div[title=\"#{@archival_object_4.title}\"]")
    expect(element).to have_text 'Suppressed'
  end
end
