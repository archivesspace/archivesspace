# frozen_string_literal: true

require_relative '../spec_helper'

describe 'System Information' do
  before(:all) do
    @repo = create(:repo)
    set_repo(@repo)

    @archivist_user = create_user(@repo => ['repository-archivists'])
    @driver = Driver.get

    @other_admin_user = create_user
    group = create(:json_group,
                     member_usernames: [@other_admin_user.username],
                     grants_permissions: ["administer_system"])
  end

  after(:all) do
    @driver ? @driver.quit : next
  end

  it 'should not let any old fool see this' do
    @driver.login_to_repo(@archivist_user, @repo)

    @driver.find_element(:link, 'System').click
    expect(@driver.find_elements(:link, 'System Information').length).to eq(0)
    @driver.get(URI.join($frontend, '/system_info'))
    assert(5) do
      expect(@driver.find_element(css: '.alert.alert-danger h2').text).to eq('Unable to Access Page')
    end
  end

  it 'should let the admin see this' do
    @driver.login_to_repo($admin, @repo)

    @driver.find_element(:link, 'System').click
    @driver.find_element(:link, 'System Information').click
    assert(5) do
      expect(@driver.find_element(css: 'h3.subrecord-form-heading').text).to eq('Frontend System Information')
    end
  end

  it 'should let users with admin privs see this' do
    @driver.login_to_repo(@other_admin_user, @repo)

    @driver.find_element(:link, 'System').click
    @driver.find_element(:link, 'System Information').click
    assert(5) do
      expect(@driver.find_element(css: 'h3.subrecord-form-heading').text).to eq('Frontend System Information')
    end
  end
end
