require 'spec_helper'
require 'rails_helper'

describe 'Classifications', js: true do
  it 'should be able to see all published resources in a repository' do
    visit('/')
    click_link 'Record Groups'
    within all('.col-sm-12')[0] do
      expect(page).to have_content("Showing Record Groups: 1 - ")
    end
  end

  it 'displays show page' do
    visit('/')
    click_link 'Record Groups'
    click_link 'My Special Classification'
  end

  it 'does not highlight repository classification uri' do
    visit('/')

    click_on 'Repositories'
    click_on 'Test Repo 1'

    elements = all('#whats-in-container form')
    link = elements.last[:action]

    visit link

    link_parts = link.split('/')
    link_parts.pop
    repository_uri = '/' + [link_parts.pop, link_parts.pop].reverse.join('/')

    expect(page).to_not have_text repository_uri
  end
end
