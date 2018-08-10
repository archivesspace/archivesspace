require 'spec_helper'
require 'rails_helper'

describe 'Resources', js: true do
  it 'should be able to see all published resources in a repository' do
    visit('/')
    click_link 'Collections'
    expect(current_path).to eq ('/repositories/resources')
    within all('.col-sm-12')[0] do
      expect(page).to have_content("Showing Collections: 1 - 3 of 3")
    end
    within all('.col-sm-12')[1] do
      expect(page.all("a[class='record-title']", text: 'Published Resource').length).to eq 1
    end
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
    expect(current_path).to eq ("#{first_href}/collection_organization")
    finished_all_ajax_requests?
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
end
