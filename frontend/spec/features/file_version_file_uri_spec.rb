# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'File Version File URI', js: true do
  before(:all) do
    @repository = create(:repo, repo_code: "file_uri_test_#{Time.now.to_i}")
    set_repo @repository

    @digital_object = create(:digital_object, title: 'Digital object with file URIs of every kind',
                                              file_versions: [{ file_uri: 'https://example.com/file.pdf' },
                                                              { file_uri: 'data:text/plain;base64,SGVsbG8=' },
                                                              { file_uri: 'javascript:alert(1)' },
                                                              { file_uri: '/root/top_secret.txt' }])

    run_index_round
  end

  before(:each) do
    login_admin
    select_repository(@repository)
  end

  it 'links only file URIs with an http, https or data: scheme' do
    visit "digital_objects/#{@digital_object.id}"

    within '#digital_object_file_versions__accordion' do
      aggregate_failures do
        expect(page).to have_css "a[href='https://example.com/file.pdf']", visible: :all
        expect(page).to have_css "a[href='data:text/plain;base64,SGVsbG8=']", visible: :all
        expect(page).not_to have_css "a[href^='javascript:']", visible: :all
        expect(page).to have_text 'javascript:alert(1)'
        expect(page).not_to have_css "a[href='/root/top_secret.txt']", visible: :all
        expect(page).to have_text '/root/top_secret.txt'
      end
    end
  end
end
