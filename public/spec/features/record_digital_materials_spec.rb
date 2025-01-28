require 'spec_helper'
require 'rails_helper'

describe 'Digital Materials listing from a record context', js: true do
  before(:all) do
    @repository = create(:repo, repo_code: "digital_materials_test_#{Time.now.to_i}")
    set_repo @repository

    @resource_with_one_do = create(:resource, {
      title: "Resource with single digital object",
      publish: true,
      id_0: "single_do_#{Time.now.to_i}"
    })

    @resource_with_multiple_do = create(:resource, {
      title: "Resource with multiple digital objects",
      publish: true,
      id_0: "multiple_do_#{Time.now.to_i}"
    })

    # Create one digital object
    @do1 = create(:digital_object, {
      publish: true,
      file_versions: [build(:file_version, {
        publish: true,
        is_representative: true,
        use_statement: 'image-service'
      })]
    })

    # Create the instance and add it to the resource
    @resource_with_one_do.instances = [build(:instance_digital, {
      digital_object: { ref: @do1.uri },
      is_representative: true
    })]
    @resource_with_one_do.save

    # Create multiple digital objects
    3.times do |i|
      do_multiple = create(:digital_object, {
        publish: true,
        file_versions: [build(:file_version, {
          publish: true,
          is_representative: true,
          use_statement: 'image-service'
        })]
      })

      # Add each digital object to the resource, only first one as representative
      @resource_with_multiple_do.instances << build(:instance_digital, {
        digital_object: { ref: do_multiple.uri },
        is_representative: (i == 0)  # Only first instance will be representative
      })
    end
    @resource_with_multiple_do.save

    run_indexers
  end

  before(:each) do
    visit('/')
    click_link 'Collections'
    fill_in 'Search within results', with: 'Resource with digital instance'
    click_button 'Search'
    click_link 'Resource with digital instance'
    click_link 'View Digital Material'
  end

  context 'identified in the breadcrumbs' do
    it 'should display a digital object linked through a published archival object' do
      expect(page).to have_content('AO with DO')
    end

    it 'should not display a digital object linked through an unpublished archival object' do
      expect(page).not_to have_content('AO with DO unpublished')
    end
  end

  describe 'Digital Objects count message' do
    it 'displays singular form when resource has one digital object' do
      visit "repositories/#{@repository.id}/resources/#{@resource_with_one_do.id}"
      expect(page).to have_content('Browse 1 digital object in collection')
    end

    it 'displays plural form when resource has multiple digital objects' do
      visit "repositories/#{@repository.id}/resources/#{@resource_with_multiple_do.id}"
      expect(page).to have_content('Browse 3 digital objects in collection')
    end
  end
end
