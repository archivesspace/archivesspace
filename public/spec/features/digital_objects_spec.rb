require 'spec_helper'
require 'rails_helper'

describe 'Digital Objects', js: true do
  def visit_digital_object_page(title)
    visit("/search?utf8=✓&op[]=&q[]='#{title}'&limit=digital_object&field[]=&from_year[]=&to_year[]=")
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

  it 'does not highlight repository uri' do
    visit('/')

    click_on 'Repositories'
    click_on 'Test Repo 1'
    find('#whats-in-container form .btn.btn-default.digital_object').click

    expect(page).to_not have_text Pathname.new(current_path).parent.to_s
  end

  describe "breadcrumbs with mixed content" do
    before(:each) do
      @repo = create(:repo, repo_code: "collection_organization_test_#{Time.now.to_i}")
      set_repo(@repo)
      @resource = create(:resource,
        title: 'This is <emph render="italic">a mixed content</emph> title',
        publish: true
      )

      @do = create(:digital_object, publish: true)
      @doc = create(:digital_object_component,
        publish: true,
        digital_object: { ref: @do.uri }
      )


      @ao = create(:archival_object,
        publish: true,
        title: 'This is <emph render="italic">another mixed content</emph> title',
        resource: {'ref' => @resource.uri},
        instances: [build(:instance_digital,
          digital_object: { ref: @do.uri },
          is_representative: true
        )]
      )
      run_indexers
    end

    it 'displays breadcrumbs when mixed content is included' do
      visit @do.uri

      within('#linked_instances_list') do
        expect(page).to have_css('span.emph.render-italic', text: 'This is a mixed content title')
        expect(page).to have_css('span.emph.render-italic', text: 'This is another mixed content title')
      end
    end
  end

  it 'displays breadcrumbs for items in the Digital Materials listing' do
    visit '/'
    click_link 'Digital Materials'
    within find('div[data-uri="/repositories/2/digital_objects/5"') do
      expect(page).to have_content('Resource with digital instance')
    end
  end
end
