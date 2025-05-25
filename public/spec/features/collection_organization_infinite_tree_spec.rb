require 'spec_helper'
require 'rails_helper'

describe 'Collection Organization', js: true do
  before(:all) do
    @repo = create(:repo, repo_code: "collection_organization_test_#{Time.now.to_i}")
    set_repo(@repo)
    @resource = create(:resource,
      title: 'This is <emph render="italic">a mixed content</emph> title',
      publish: true
    )
    @ao3 = create(:archival_object,
      resource: {'ref' => @resource.uri},
      publish: true
    )
    @ao4 = create(:archival_object,
      resource: {'ref' => @resource.uri},
      publish: true
    )
    @ao5 = create(:archival_object,
      resource: {'ref' => @resource.uri},
      publish: true
    )
    @ao6 = create(:archival_object,
      resource: {'ref' => @resource.uri},
      publish: true
    )
    @ao7 = create(:archival_object,
      resource: {'ref' => @resource.uri},
      publish: true
    )

    # The reason for the full 120 children instead of the more efficient 101: with the decreased WAYPOINT_SIZE
    # for testing, an extra batch gets fetched when the tree scrolls the node of interest into view 
    # during the last batch test with 101 children. The correct behavior can be observed in local development
    # by commenting out the `this.batchObserver.observe(node)` call in `InfiniteTree.renderAncestors`
    # Create children for ao7 (101 children = 6 batches)
    120.times do |i|
      instance_variable_set("@ao#{i + 1}_of_ao7", create(:archival_object,
        resource: {'ref' => @resource.uri},
        parent: {'ref' => @ao7.uri},
        publish: true
      ))
    end

    # Create children for ao3 (81 children)
    81.times do |i|
      instance_variable_set("@ao#{i + 1}_of_ao3", create(:archival_object,
        resource: {'ref' => @resource.uri},
        parent: {'ref' => @ao3.uri},
        publish: true
      ))
    end

    # Create children for ao4 (41 children)
    41.times do |i|
      instance_variable_set("@ao#{i + 1}_of_ao4", create(:archival_object,
        resource: {'ref' => @resource.uri},
        parent: {'ref' => @ao4.uri},
        publish: true
      ))
    end

    # Create children for ao5 (21 children)
    21.times do |i|
      instance_variable_set("@ao#{i + 1}_of_ao5", create(:archival_object,
        resource: {'ref' => @resource.uri},
        parent: {'ref' => @ao5.uri},
        publish: true
      ))
    end

    # Create one child for ao6
    @ao1_of_ao6 = create(:archival_object,
      resource: {'ref' => @resource.uri},
      parent: {'ref' => @ao6.uri},
      publish: true
    )

    run_indexers
  end

  shared_examples 'batch rendering' do |node_var, expected_node_count, batch_placeholders|
    it "loads the correct number of siblings" do
      visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization#tree::archival_object_#{instance_variable_get(node_var).id}"
      wait_for_jquery
      node = find("#archival_object_#{instance_variable_get(node_var).id}.current")
      parent_list = node.find(:xpath, '..')
      expect(parent_list).to have_css('.node', count: expected_node_count)
      if batch_placeholders.length > 0
        expect(parent_list).to have_css('[data-batch-placeholder]', count: batch_placeholders.length, visible: false)
        batch_placeholders.each do |batch_num|
          expect(parent_list).to have_css("[data-batch-placeholder='#{batch_num}']", visible: false)
        end
      else
        expect(parent_list).to_not have_css('[data-batch-placeholder]')
      end
    end
  end

  describe 'should load the correct number of siblings' do
    context 'when the node of interest is in the first batch' do
      it_behaves_like 'batch rendering', "@ao#{rand(1..20)}_of_ao3", 40, [2, 3, 4]
      it_behaves_like 'batch rendering', "@ao#{rand(1..20)}_of_ao4", 40, [2]
      it_behaves_like 'batch rendering', "@ao#{rand(1..20)}_of_ao5", 21, []
      it_behaves_like 'batch rendering', '@ao1_of_ao6', 1, []
      it_behaves_like 'batch rendering', "@ao#{rand(1..20)}_of_ao7", 40, [2, 3, 4, 5]
    end

    context 'when the node of interest is in the second batch' do
      it_behaves_like 'batch rendering', "@ao#{rand(21..40)}_of_ao3", 60, [3, 4]
      it_behaves_like 'batch rendering', "@ao#{rand(21..40)}_of_ao4", 41, []
      it_behaves_like 'batch rendering', '@ao21_of_ao5', 21, []
      it_behaves_like 'batch rendering', "@ao#{rand(21..40)}_of_ao7", 60, [3, 4, 5]
    end

    context 'when the node of interest is in the last batch' do
      it_behaves_like 'batch rendering', '@ao81_of_ao3', 41, [1, 2]
      it_behaves_like 'batch rendering', '@ao41_of_ao4', 41, []
      it_behaves_like 'batch rendering', "@ao#{rand(100..120)}_of_ao7", 60, [1, 2, 3]
    end

    context 'when the node of interest is in a batch between the third and second to last batches' do
      it_behaves_like 'batch rendering', "@ao#{rand(41..60)}_of_ao3", 80, [4]
      it_behaves_like 'batch rendering', "@ao#{rand(61..80)}_of_ao3", 61, [1]
      it_behaves_like 'batch rendering', "@ao#{rand(81..100)}_of_ao7", 61, [1, 2]
      it_behaves_like 'batch rendering', "@ao#{rand(41..60)}_of_ao7", 80, [4, 5]
    end
  end
end
