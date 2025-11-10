require 'spec_helper'
require 'rails_helper'

describe 'Resources', js: true do
  it 'should be able to see all published resources in a repository' do
    visit('/')
    click_link 'Collections'
    expect(current_path).to eq ('/repositories/resources')
    within all('.col-sm-12')[0] do
      expect(page).to have_content("Showing Collections: 1 - ")
    end
    within all('.col-sm-12')[1] do
      expect(page.all("a[class='record-title']", text: 'Published Resource').length).to eq 1
    end

    aggregate_failures 'supporting accessibility by not skipping heading levels' do
      expect(page).to be_axe_clean.checking_only :'heading-order'
    end
  end

  it 'does not highlight repository uri' do
    visit('/')

    click_on 'Repositories'
    click_on 'Test Repo 1'
    find('#whats-in-container form .btn.btn-default.resource').click

    expect(page).to_not have_text Pathname.new(current_path).parent.to_s
  end

  it 'should be able to properly navigate from Collection Organization back to Resource' do
    visit('/')
    click_link 'Collections'
    expect(current_path).to eq ('/repositories/resources')
    first_title = ''
    first_href = ''
    within all('.col-sm-12')[1] do
      first_title = first("a[class='record-title']").text
      href = first("a")['href'].split('/')
      first_href = '/' + href[3..href.length].join('/')
      first("a[class='record-title']").click
    end
    expect(current_path).to eq (first_href)
    click_link 'Collection Organization'

    aggregate_failures 'should not duplicate ids' do
      expect(page).to be_axe_clean.checking_only :'duplicate-id'
    end

    expect(current_path).to eq ("#{first_href}/collection_organization")
    page.go_back
    expect(current_path).to eq (first_href)
    finished_all_ajax_requests?
    expect(page).not_to(
      have_content(
        'Your request could not be completed due to an unexpected error'
      )
    )
    expect(page).to have_content(first_title)
  end

  it "displays related digital objects" do
    visit('/')
    click_link 'Collections'
    fill_in 'Search within results', with: 'Resource with digital instance'
    click_button 'Search'
    click_link 'Resource with digital instance'

    aggregate_failures 'supporting accessibility by not skipping heading levels' do
      expect(page).to be_axe_clean.checking_only :'heading-order'
    end

    aggregate_failures 'should not duplicate ids' do
      expect(page).to be_axe_clean.checking_only :'duplicate-id'
    end

    aggregate_failures 'supporting accessibility by resizing sidebar with keyboard' do
      page.has_css? 'div.sidebar'

      sidebar_width = find('div.sidebar').evaluate_script("window.getComputedStyle(this)['width']")
      handle = find('input.resizable-sidebar-handle')

      5.times do
        handle.native.send_keys :arrow_left
      end

      new_sidebar_width = find('div.sidebar').evaluate_script("window.getComputedStyle(this)['width']")
      expect(new_sidebar_width).to be < sidebar_width

      10.times do
        handle.native.send_keys :arrow_right
      end

      newest_sidebar_width = find('div.sidebar').evaluate_script("window.getComputedStyle(this)['width']")
      expect(newest_sidebar_width).to be > sidebar_width
    end

    aggregate_failures 'should not duplicate ids when viewing container inventory' do
      click_link 'Container Inventory'
      expect(page).to be_axe_clean.checking_only :'duplicate-id'
    end

    click_link 'View Digital Material'
    expect(page).to have_content('Digital Record')
  end

  it 'displays deaccessions on show page' do
    visit('/')
    click_link 'Collections'
    fill_in 'Search within results', with: 'Resource with Deaccession'
    click_button 'Search'
    click_link 'Resource with Deaccession'
    expect(page).to have_content('Deaccessions')
  end

  it 'displays accessions on show page' do
    visit('/')
    click_link 'Collections'
    fill_in 'Search within results', with: 'Resource with Accession'
    click_button 'Search'
    click_link 'Resource with Accession'
    expect(page).to have_content('Related Unprocessed Material')
  end

  it 'displays linked agents on show page, with creators in top section but not in related names' do
    visit('/')
    click_link 'Collections'
    fill_in 'Search within results', with: 'Resource with Agents'
    click_button 'Search'
    click_link 'Resource with Agents'

    expect(page).to have_content('Linked Agent 1')
    expect(page).to have_css('#agent_list', text: 'Linked Agent 2')
    expect(page).to_not have_css('#agent_list', text: 'Linked Agent 1')
  end

  it "Does not display finding aid status if unpublished" do
    visit('/')
    click_link 'Collections'
    click_link 'Published Resource'
    expect(page).to_not have_content('In Progress')
  end

  it 'downloads the resource to a PDF file' do
    resource = create(:resource,
      title: "Resource PDF Download Test",
      ead_id: 'text(us::paav::b jd99:: blake carver papers)//es" "carver.xml"',
      publish: true,
      is_finding_aid_status_published: false,
      finding_aid_status: "in_progress",
    )

    run_indexers

    visit('/')
    fill_in 'q0', with: resource.title
    click_on 'Search'
    click_on resource.title

    click_on 'Download PDF'

    pdf_files = Dir.glob(File.join(Dir.tmpdir, '*.pdf'))
    expect(pdf_files).to include "#{Dir.tmpdir}/text_us_paav_b_jd99_blake_carver_papers_es_carver_xml.pdf"
  end

  it 'downloads PDF from archival object view' do
    # Clean existing PDFs
    Dir.glob(File.join(Dir.tmpdir, '*.pdf')).each { |file| File.delete(file) }

    resource = create(:resource,
      title: "Resource with Archival Object",
      publish: true
    )

    archival_object = create(:archival_object,
      title: "Archival Object PDF Test",
      resource: { 'ref' => resource.uri },
      publish: true
    )

    run_indexers

    visit('/')
    fill_in 'q0', with: archival_object.title
    click_on 'Search'
    click_on archival_object.title

    click_on 'Download PDF'

    pdf_files = Dir.glob(File.join(Dir.tmpdir, '*.pdf'))
    expect(pdf_files.length).to eq(1)
  end

  it 'shows PDF download button only for resources and their published components' do
    # Clean existing PDFs
    Dir.glob(File.join(Dir.tmpdir, '*.pdf')).each { |file| File.delete(file) }

    # Create a resource and an archival object
    resource = create(:resource,
      title: "Resource with Component",
      publish: true
    )

    archival_object = create(:archival_object,
      title: "Component with Resource",
      resource: { 'ref' => resource.uri },
      publish: true
    )

    # Create a second resource and component
    resource2 = create(:resource,
      title: "Second Resource",
      publish: true
    )

    # Create component but don't publish it
    unpublished_ao = create(:archival_object,
      title: "Unpublished Component",
      resource: { 'ref' => resource2.uri },
      publish: false
    )

    run_indexers

    # Check resource view
    visit('/')
    fill_in 'q0', with: resource.title
    click_on 'Search'
    find('a.record-title', text: resource.title, match: :first).click
    expect(page).to have_button('Download PDF')

    # Check published component view
    visit('/')
    fill_in 'q0', with: archival_object.title
    click_on 'Search'
    find('a.record-title', text: archival_object.title, match: :first).click
    expect(page).to have_button('Download PDF')

    # Check unpublished component
    visit('/')
    fill_in 'q0', with: unpublished_ao.title
    click_on 'Search'
    expect(page).not_to have_content(unpublished_ao.title)
  end
end
