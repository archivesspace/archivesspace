require 'date'
require 'spec_helper.rb'
require 'rails_helper.rb'

describe 'AdvancedSearchDates', js: true do

  before(:all) do
    @repository = create(:repo, repo_code: "advanced_search_dates_test_#{Time.now.to_i}")
    set_repo(@repository)

    @user = create_user(@repository => ['repository-archivists'])
  end

  before(:each) do
    login_user(@user)

    ensure_repository_access

    # Open the dropdown only if its not already open
    if !page.has_css?('.advanced-search-add-row-dropdown')
      first('button[title="Show Advanced Search"]').click
    end

    first('.advanced-search-add-row-dropdown').click
    first('.advanced-search-add-date-row').click
    page.has_css? 'input#v1.date-field'

    @date_field = find 'input#v1.date-field'
    @submit_btn = find 'form.advanced-search .btn.btn-primary'

    now = DateTime.now
    @year = now.strftime('%Y')
    @month = now.strftime('%Y-%m')
    @day = now.strftime('%Y-%m-%d')
  end

  it 'accepts a year date in yyyy format' do
    within "form.advanced-search" do
      @date_field.fill_in(with: @year)
      @date_field.send_keys :escape
      @submit_btn.click
    end

    expect(page).to have_text 'Search Results'
  end

  it 'accepts a month date in yyyy-mm format' do
    within "form.advanced-search" do
      @date_field.fill_in(with: @month)
      @date_field.send_keys :escape
      @submit_btn.click
    end

    expect(page).to have_text 'Search Results'
  end

  it 'accepts a day date in yyyy-mm-dd format' do
    within "form.advanced-search" do
      @date_field.fill_in(with: @day)
      @date_field.send_keys :escape
      @submit_btn.click
    end

    expect(page).to have_text 'Search Results'
  end

end
