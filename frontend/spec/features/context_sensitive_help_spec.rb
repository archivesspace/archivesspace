# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Context Sensitive Help', js: true do
  before(:each) do
    login_admin
  end

  it 'displays a clickable tooltip for a field label' do
    visit('/accessions/new')

    find('label[for="accession_title_"]').hover
    # wait for the tooltip to appear
    find('.tooltip-inner')
    expect(page).to have_content('The title assigned')

    # hover somewhere else to make it disappear
    find('h2', text: 'New Accession').hover
    expect(page).not_to have_content('The title assigned')
  end
end
