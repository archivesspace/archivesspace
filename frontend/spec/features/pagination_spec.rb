# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Pagination', js: true do
  before(:all) do
    now = Time.now.to_i
    @repository = create(:repo, repo_code: "pagination_test_#{now}")

    set_repo @repository

    @manager_user = create_user(@repository => ['repository-managers'])

    total_records = AppConfig[:default_page_size].to_i * 2 + 1
    (1..total_records).each do |index|
      create(:accession, title: "Accession Title #{index} #{now}")
      create(:digital_object, title: "Digital object #{index} #{now}")
    end

    run_index_round
  end

  before(:each) do
    login_user(@manager_user)
    select_repository(@repository)
  end

  it 'can navigate through pages of accessions' do
    click_on 'Browse'
    click_on 'Accessions'

    expect(page).to have_text "Showing 1 - #{AppConfig[:default_page_size]}"

    find("[title='Next']").click

    expect(page).to have_text "Showing #{AppConfig[:default_page_size] + 1} - #{AppConfig[:default_page_size] * 2}"
  end

  it 'can navigate through pages of digital objects' do
    click_on 'Browse'
    click_on 'Digital Objects'

    expect(page).to have_text "Showing 1 - #{AppConfig[:default_page_size]}"

    find("[title='Next']").click

    expect(page).to have_text "Showing #{AppConfig[:default_page_size] + 1} - #{AppConfig[:default_page_size] * 2}"
  end
end
