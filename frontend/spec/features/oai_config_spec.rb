# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'OAI-PMH Settings', js: true do
  before(:all) do
    now = Time.now.to_i

    @first_repository = create(:repo, repo_code: "oai_set_first_#{now}", publish: true)
    @second_repository = create(:repo, repo_code: "oai_set_second_#{now}", publish: true)
  end

  before(:each) do
    login_admin
    select_repository(@first_repository)

    visit_oai_config
    remove_every_oai_set
  end

  def oai_set_entries
    '.subrecord-form-container > .subrecord-form-list > li'
  end

  def visit_oai_config
    click_on 'System'
    click_on 'Manage OAI-PMH Settings'
    wait_for_ajax
  end

  def save_oai_config
    first(:button, 'Update OAI-PMH Settings').click

    expect(page).to have_css('.alert.alert-success', text: 'OAI-PMH settings successfully updated!')
  end

  def oai_set_entry(section_id, set_name)
    find("##{section_id} input[type='text'][value='#{set_name}']").ancestor('li', match: :first)
  end

  def add_oai_set_entry(section_id, add_button_label)
    section = find("##{section_id}")
    entry_count = section.all(oai_set_entries).length

    # A second add button appears below a non-empty list
    section.find('.subrecord-form-heading').click_on add_button_label

    expect(section).to have_css(oai_set_entries, count: entry_count + 1)

    section.all(oai_set_entries).last
  end

  def remove_every_oai_set
    %w[repository_set sponsor_set].each do |section_id|
      section = find("##{section_id}")

      while (entry = section.all(oai_set_entries).first)
        entry_count = section.all(oai_set_entries).length

        within entry do
          find('.subrecord-form-remove').click
          find('.confirm-removal').click
        end

        expect(section).to have_css(oai_set_entries, count: entry_count - 1)
      end
    end
  end

  def add_repository_set(set_name, repo_codes)
    within add_oai_set_entry('repository_set', 'Add Repository Set') do
      fill_in 'Repository Set Name', with: set_name
      fill_in 'Repository Set Description', with: "#{set_name} description"

      repo_codes.each { |repo_code| check repo_code, exact: true }
    end
  end

  def add_sponsor_set(set_name, sponsors)
    within add_oai_set_entry('sponsor_set', 'Add Sponsor Set') do
      fill_in 'Sponsor Set Name', with: set_name
      fill_in 'Sponsor Set Description', with: "#{set_name} description"

      # Tag widget: one tag per return
      tag_field = find('.bootstrap-tagsinput input[type="text"]')

      sponsors.each { |sponsor| tag_field.send_keys(sponsor, :enter) }
    end
  end

  def repositories_in_set(set_name)
    oai_set_entry('repository_set', set_name)
      .all('input[type="checkbox"]', visible: :all)
      .select { |checkbox| checkbox.checked? }
      .map { |checkbox| checkbox[:value] }
  end

  def sponsors_in_set(set_name)
    oai_set_entry('sponsor_set', set_name)
      .all('.bootstrap-tagsinput .tag')
      .map(&:text)
  end

  it 'persists a repository set covering more than one repository' do
    repo_codes = [@first_repository.repo_code, @second_repository.repo_code]

    add_repository_set('oai_multi_repo_set', repo_codes)
    save_oai_config

    visit_oai_config

    expect(repositories_in_set('oai_multi_repo_set')).to match_array(repo_codes)
  end

  it 'persists a sponsor set covering more than one sponsor' do
    sponsors = ['Sponsor One', 'Sponsor Two', 'Sponsor Three']

    add_sponsor_set('oai_multi_sponsor_set', sponsors)
    save_oai_config

    visit_oai_config

    expect(sponsors_in_set('oai_multi_sponsor_set')).to match_array(sponsors)
  end

  it 'persists several repository sets and sponsor sets saved together' do
    add_repository_set('oai_repo_set_one', [@first_repository.repo_code])
    add_repository_set('oai_repo_set_two', [@second_repository.repo_code])
    add_sponsor_set('oai_sponsor_set_one', ['Sponsor One'])
    add_sponsor_set('oai_sponsor_set_two', ['Sponsor Two', 'Sponsor Three'])

    save_oai_config

    visit_oai_config

    expect(repositories_in_set('oai_repo_set_one')).to eq([@first_repository.repo_code])
    expect(repositories_in_set('oai_repo_set_two')).to eq([@second_repository.repo_code])
    expect(sponsors_in_set('oai_sponsor_set_one')).to eq(['Sponsor One'])
    expect(sponsors_in_set('oai_sponsor_set_two')).to match_array(['Sponsor Two', 'Sponsor Three'])
  end
end
