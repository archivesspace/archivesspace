require 'spec_helper'
require 'rails_helper'

describe 'Digital Objects', js: true do
  def visit_digital_object_page(title)
    visit '/'
    click_link 'Digital Materials'
    click_link title
  end

  describe "Born Digital" do
    before(:each) do
      visit_digital_object_page('Born digital')
    end

    it 'should be accessible from the browse page' do
      expect(current_path).to match(/repositories.*digital_objects\/\d+/)
    end

    it 'should display a link to a related published accession' do
      expect(page).to have_content('Published Accession')
    end

    it 'should not display a link to a related but unpublished accession' do
      expect(page).to_not have_content('Unpublished Accession')
    end
  end

  describe "Digital Object With Classification" do
    before(:each) do
      visit_digital_object_page('Digital Object With Classification')
    end

    it 'should show linked classification details for digital objects' do
      expect(page).to have_content('Record Groups')
    end
  end

  describe "Digital Object With Classification" do
    it "should display image tag for digital object file version" do
      visit_digital_object_page('Digital Object With File Version')
      expect(page).to have_css('#objectimage img')
    end
  end
end
