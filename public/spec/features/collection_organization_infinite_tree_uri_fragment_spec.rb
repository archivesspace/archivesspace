require 'spec_helper'
require 'rails_helper'

describe 'Collection Organization', js: true do
  before(:all) do
    @repo = create(:repo, repo_code: "collection_organization_test_#{Time.now.to_i}")
    set_repo(@repo)

    @tree_batch_size = Rails.configuration.infinite_tree_batch_size
  end

  describe 'InfiniteTree' do
    before(:all) do
      @resource = create(:resource, publish: true)
      @ao1 = create(:archival_object, resource: {'ref' => @resource.uri}, publish: true)
      @ao2 = create(:archival_object, resource: {'ref' => @resource.uri}, publish: true)
      @ao3 = create(:archival_object, resource: {'ref' => @resource.uri}, publish: true)
      @ao4 = create(:archival_object, resource: {'ref' => @resource.uri}, publish: true)
      @ao5 = create(:archival_object, resource: {'ref' => @resource.uri}, publish: true)
      @ao6 = create(:archival_object, resource: {'ref' => @resource.uri}, publish: true)
      @ao7 = create(:archival_object, resource: {'ref' => @resource.uri}, publish: true)

      @ao1_of_ao1 = create(:archival_object, # 1 batch with a single node
        resource: {'ref' => @resource.uri},
        parent: {'ref' => @ao1.uri},
        publish: true
      )

      5.times do |i| # 1 batch with multiple nodes
        instance_variable_set("@ao#{i + 1}_of_ao2", create(:archival_object,
          resource: {'ref' => @resource.uri},
          parent: {'ref' => @ao2.uri},
          publish: true
        ))
      end

      31.times do |i| # 2 batches
        instance_variable_set("@ao#{i + 1}_of_ao3", create(:archival_object,
          resource: {'ref' => @resource.uri},
          parent: {'ref' => @ao3.uri},
          publish: true
        ))
      end

      61.times do |i| # 3 batches
        instance_variable_set("@ao#{i + 1}_of_ao4", create(:archival_object,
          resource: {'ref' => @resource.uri},
          parent: {'ref' => @ao4.uri},
          publish: true
        ))
      end

      91.times do |i| # 4 batches
        instance_variable_set("@ao#{i + 1}_of_ao5", create(:archival_object,
          resource: {'ref' => @resource.uri},
          parent: {'ref' => @ao5.uri},
          publish: true
        ))
      end

      @resource2 = create(:resource, publish: true)
      31.times do |i| # 2 batches
        instance_variable_set("@ao#{i + 1}_of_resource2", create(:archival_object,
          resource: {'ref' => @resource2.uri},
          publish: true
        ))
      end

      @resource3 = create(:resource, publish: true)
      61.times do |i| # 3 batches
        instance_variable_set("@ao#{i + 1}_of_resource3", create(:archival_object,
          resource: {'ref' => @resource3.uri},
          publish: true
        ))
      end

      run_indexers
    end

    RSpec::Matchers.define :appear_in_tree_viewport do
      match do |node|
        tree = find('#infinite-tree-container')
        tree_rect = page.evaluate_script('arguments[0].getBoundingClientRect()', tree)
        node_rect = page.evaluate_script('arguments[0].getBoundingClientRect()', node)
        node_top_in_view = node_rect['top'] >= tree_rect['top'] && node_rect['top'] <= tree_rect['bottom']
        node_bottom_in_view = node_rect['bottom'] >= tree_rect['top'] && node_rect['bottom'] <= tree_rect['bottom']

        node_top_in_view && node_bottom_in_view
      end
    end

    shared_examples 'basic details of uri fragment batch rendering' do
      it 'shows the node of interest' do
        node_row = node.find('& > .node-row')
        expect(node_row).to appear_in_tree_viewport
      end

      it 'loads the correct number of sibling nodes' do
        expect(parent_list).to have_css('.node', count: expected_node_count_on_page_load)
      end
    end

    shared_examples 'loading the first batch' do
      it 'contains the first batch' do
        aggregate_failures 'includes the first node of the batch' do
          curr_node_id = instance_variable_get("@ao1_of_#{parent}").id
          expect(parent_list).to have_css("& #archival_object_#{curr_node_id}:first-child")
        end

        aggregate_failures 'includes the middle nodes of the batch' do
          (2..@tree_batch_size - 1).each do |node_num|
            curr_node_id = instance_variable_get("@ao#{node_num}_of_#{parent}").id
            next_node_id = instance_variable_get("@ao#{node_num + 1}_of_#{parent}").id
            expect(parent_list).to have_css("#archival_object_#{curr_node_id} + #archival_object_#{next_node_id}")
          end
        end

        aggregate_failures 'includes the last node of the batch' do
          curr_node_id = instance_variable_get("@ao#{@tree_batch_size}_of_#{parent}").id
          prev_node_id = instance_variable_get("@ao#{@tree_batch_size - 1}_of_#{parent}").id
          expect(parent_list).to have_css("#archival_object_#{prev_node_id} + #archival_object_#{curr_node_id}")
        end
      end
    end

    shared_examples 'loading middle batches' do
      it 'loads middle batches of nodes in the correct order' do
        expected_populated_batches.each do |batch_offset|
          next if batch_offset == 0 # skip first batch, already tested
          next if batch_offset == total_batches - 1 # skip last batch, already tested

          prev_batch_was_populated = expected_populated_batches.include?(batch_offset - 1)
          curr_batch_first_node_id = instance_variable_get("@ao#{batch_offset * @tree_batch_size + 1}_of_#{parent}").id

          if prev_batch_was_populated
            aggregate_failures 'loads the first node of the current batch after the last node of the previous batch' do
              prev_batch_last_node_id = instance_variable_get("@ao#{batch_offset * @tree_batch_size}_of_#{parent}").id
              expect(parent_list).to have_css("#archival_object_#{prev_batch_last_node_id} + #archival_object_#{curr_batch_first_node_id}")
            end
          else
            aggregate_failures 'loads the first node of the current batch after the previous batch placeholder' do
              expect(parent_list).to have_css("[data-batch-placeholder='#{batch_offset - 1}'] + #archival_object_#{curr_batch_first_node_id}", visible: :all)
            end
          end

          (batch_offset * @tree_batch_size + 1..(batch_offset + 1) * @tree_batch_size).each do |node_num|
            curr_node_id = instance_variable_get("@ao#{node_num}_of_#{parent}").id

            if node_num < (batch_offset + 1) * @tree_batch_size
              aggregate_failures 'loads the first through the second-to-last node of the current batch in order' do
                next_node_id = instance_variable_get("@ao#{node_num + 1}_of_#{parent}").id
                expect(parent_list).to have_css("#archival_object_#{curr_node_id} + #archival_object_#{next_node_id}")
              end
            else
              aggregate_failures 'loads the last node of the current batch in order' do
                prev_node_id = instance_variable_get("@ao#{node_num - 1}_of_#{parent}").id
                expect(parent_list).to have_css("#archival_object_#{prev_node_id} + #archival_object_#{curr_node_id}")
              end
            end

          end
        end
      end
    end

    shared_examples 'loading the last batch' do
      it 'loads the last batch' do
        batch_offset = total_batches - 1
        second_to_last_batch_last_node_id = instance_variable_get("@ao#{batch_offset * @tree_batch_size}_of_#{parent}").id
        last_batch_first_node_position = batch_offset * @tree_batch_size + 1
        last_batch_first_node_id = instance_variable_get("@ao#{last_batch_first_node_position}_of_#{parent}").id

        aggregate_failures 'loads the first node of the last batch' do
          expect(parent_list).to have_css("#archival_object_#{second_to_last_batch_last_node_id} + #archival_object_#{last_batch_first_node_id}")
        end

        if last_batch_first_node_position < total_nodes # not last node in this batch
          (last_batch_first_node_position..total_nodes).each do |node_num|
            curr_node_id = instance_variable_get("@ao#{node_num}_of_#{parent}").id

            if node_num < total_nodes
              aggregate_failures 'loads the middle nodes of the last batch in the correct order' do
                next_node_id = instance_variable_get("@ao#{node_num + 1}_of_#{parent}").id
                expect(parent_list).to have_css("#archival_object_#{curr_node_id} + #archival_object_#{next_node_id}")
              end
            else
              aggregate_failures 'loads the last node of the last batch' do
                prev_node_id = instance_variable_get("@ao#{node_num - 1}_of_#{parent}").id
                expect(parent_list).to have_css("#archival_object_#{prev_node_id} + #archival_object_#{curr_node_id}")
                expect(parent_list).to have_css("& #archival_object_#{curr_node_id}:last-child")
              end
            end

          end
        end
      end
    end

    shared_examples 'including placeholders for non-loaded batches' do
      it 'includes placeholders for batches that are not populated' do
        expected_batch_placeholders.each do |batch_offset|
          prev_batch_was_populated = expected_populated_batches.include?(batch_offset - 1)

          if prev_batch_was_populated
            aggregate_failures 'includes a placeholder after the last node of the previous batch' do
              prev_batch_last_node_id = instance_variable_get("@ao#{batch_offset * @tree_batch_size}_of_#{parent}").id
              expect(parent_list).to have_css("#archival_object_#{prev_batch_last_node_id} + [data-batch-placeholder='#{batch_offset}']", visible: :all)
            end
          else
            aggregate_failures 'includes a placeholder after the previous placeholder' do
              expect(parent_list).to have_css("[data-batch-placeholder='#{batch_offset - 1}'] + [data-batch-placeholder='#{batch_offset}']", visible: false)
            end
          end
        end
      end
    end

    shared_examples 'including the last batch placeholder' do
      it 'includes the last batch placeholder' do
        expect(parent_list).to have_css("& [data-batch-placeholder='#{total_batches - 1}']:last-child", visible: :all)
      end
    end

    shared_examples 'scrolling loads remaining batches' do
      it 'fetches remaining batches of siblings on scroll' do
        container = page.find('#infinite-tree-container')

        expected_batch_placeholders.each do |batch_offset|
          wait_for_jquery
          observer_node = parent_list.first("[data-observe-offset='#{batch_offset}']")
          container.scroll_to(observer_node, align: :center)
        end

        wait_for_jquery
        expect(parent_list).to have_css('.node', count: total_nodes)
        expect(parent_list).not_to have_css('[data-batch-placeholder]', visible: false)
      end
    end

    shared_examples 'having all nodes loaded' do
      it 'has all sibling nodes loaded' do
        expect(parent_list).to have_css('.node', count: total_nodes)
        expect(parent_list).not_to have_css('[data-batch-placeholder]', visible: false)
      end
    end

    context 'when loading a page with a URI fragment' do
      let(:total_batches) { (total_nodes / @tree_batch_size.to_f).ceil }

      context 'when the target node is not the root node' do
        let(:node_record_id) do
          node_var = "@ao#{node_position}_of_#{parent}"
          instance_variable_get(node_var).id
        end

        let!(:node) do
          visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization#tree::archival_object_#{node_record_id}"
          wait_for_jquery

          find("#archival_object_#{node_record_id}.current")
        end

        let(:parent_list) { node.find(:xpath, '..') }

        context "the target node's parent has 1 batch of child nodes" do
          context 'containing a single node' do
            let(:parent) { 'ao1' }
            let(:total_nodes) { 1 }
            let(:batch_target) { 0 }
            let(:expected_node_count_on_page_load) { 1 }
            let(:expected_populated_batches) { [0] }
            let(:expected_batch_placeholders) { [] }
            let(:node_position) { 1 }

            it_behaves_like 'basic details of uri fragment batch rendering'
            it_behaves_like 'having all nodes loaded'

            describe 'the parent list' do
              it 'contains the node' do
                aggregate_failures 'does not contain a data batch placeholder' do
                  expect(parent_list).not_to have_css('[data-batch-placeholder]', visible: false)
                end

                aggregate_failures 'loads the node' do
                  expect(parent_list).to have_css("#archival_object_#{node_record_id}")
                end
              end
            end
          end

          context 'containing multiple nodes' do
            let(:parent) { 'ao2' }
            let(:total_nodes) { 5 }
            let(:batch_target) { 0 }
            let(:expected_node_count_on_page_load) { 5 }
            let(:expected_populated_batches) { [0] }
            let(:expected_batch_placeholders) { [] }
            let(:node_position) { 2 }

            it_behaves_like 'basic details of uri fragment batch rendering'
            it_behaves_like 'having all nodes loaded'

            describe 'the parent list' do
              it 'contains the first batch' do
                aggregate_failures 'does not contain a data batch placeholder' do
                  expect(parent_list).not_to have_css('[data-batch-placeholder]', visible: false)
                end

                aggregate_failures 'includes the first node of the batch' do
                  curr_node_id = instance_variable_get("@ao1_of_#{parent}").id
                  expect(parent_list).to have_css("& #archival_object_#{curr_node_id}:first-child")
                end

                aggregate_failures 'includes the middle nodes of the batch' do
                  (2..total_nodes - 1).each do |node_num|
                    curr_node_id = instance_variable_get("@ao#{node_num}_of_#{parent}").id
                    next_node_id = instance_variable_get("@ao#{node_num + 1}_of_#{parent}").id
                    expect(parent_list).to have_css("#archival_object_#{curr_node_id} + #archival_object_#{next_node_id}")
                  end
                end

                aggregate_failures 'includes the last node of the batch' do
                  curr_node_id = instance_variable_get("@ao#{total_nodes}_of_#{parent}").id
                  prev_node_id = instance_variable_get("@ao#{total_nodes - 1}_of_#{parent}").id
                  expect(parent_list).to have_css("#archival_object_#{prev_node_id} + #archival_object_#{curr_node_id}")
                end
              end
            end
          end
        end

        context "the target node's parent has 2 batches of child nodes" do
          let(:parent) { 'ao3' }
          let(:total_nodes) { 31 }

          context 'and the target node is in the first batch' do
            let(:batch_target) { 0 }
            let(:expected_node_count_on_page_load) { 31 }
            let(:expected_populated_batches) { [0, 1] }
            let(:expected_batch_placeholders) { [] }
            let(:node_position) { 15 }

            it_behaves_like 'basic details of uri fragment batch rendering'
            it_behaves_like 'loading the first batch'
            it_behaves_like 'loading the last batch'
            it_behaves_like 'having all nodes loaded'
          end

          context 'and the target node is in the second batch' do
            let(:batch_target) { 1 }
            let(:expected_node_count_on_page_load) { 31 }
            let(:expected_populated_batches) { [0, 1] }
            let(:expected_batch_placeholders) { [] }
            let(:node_position) { 31 }

            it_behaves_like 'basic details of uri fragment batch rendering'
            it_behaves_like 'loading the first batch'
            it_behaves_like 'loading the last batch'
            it_behaves_like 'having all nodes loaded'
          end
        end

        context "the target node's parent has 3 batches of child nodes" do
          let(:parent) { 'ao4' }
          let(:total_nodes) { 61 }

          context 'and the target node is in the first batch' do
            let(:batch_target) { 0 }
            let(:expected_node_count_on_page_load) { 60 }
            let(:expected_populated_batches) { [0, 1] }
            let(:expected_batch_placeholders) { [2] }
            let(:node_position) { 15 }

            it_behaves_like 'basic details of uri fragment batch rendering'
            it_behaves_like 'loading the first batch'
            it_behaves_like 'loading middle batches'
            it_behaves_like 'including placeholders for non-loaded batches'
            it_behaves_like 'including the last batch placeholder'
            it_behaves_like 'scrolling loads remaining batches'
          end

          context 'and the target node is in the second batch' do
            let(:batch_target) { 1 }
            let(:expected_node_count_on_page_load) { 61 }
            let(:expected_populated_batches) { [0, 1, 2] }
            let(:expected_batch_placeholders) { [] }
            let(:node_position) { 45 }

            it_behaves_like 'basic details of uri fragment batch rendering'
            it_behaves_like 'loading the first batch'
            it_behaves_like 'loading middle batches'
            it_behaves_like 'loading the last batch'
            it_behaves_like 'having all nodes loaded'
          end

          context 'and the target node is in the third batch' do
            let(:batch_target) { 2 }
            let(:expected_node_count_on_page_load) { 61 }
            let(:expected_populated_batches) { [0, 1, 2] }
            let(:expected_batch_placeholders) { [] }
            let(:node_position) { 61 }

            it_behaves_like 'basic details of uri fragment batch rendering'
            it_behaves_like 'loading the first batch'
            it_behaves_like 'loading middle batches'
            it_behaves_like 'loading the last batch'
            it_behaves_like 'having all nodes loaded'
          end
        end

        context "the target node's parent has 4 batches of child nodes" do
          let(:parent) { 'ao5' }
          let(:total_nodes) { 91 }

          context 'and the target node is in the first batch' do
            let(:batch_target) { 0 }
            let(:expected_node_count_on_page_load) { 60 }
            let(:expected_populated_batches) { [0, 1] }
            let(:expected_batch_placeholders) { [2, 3] }
            let(:node_position) { 25 }

            it_behaves_like 'basic details of uri fragment batch rendering'
            it_behaves_like 'loading the first batch'
            it_behaves_like 'loading middle batches'
            it_behaves_like 'including placeholders for non-loaded batches'
            it_behaves_like 'including the last batch placeholder'
            it_behaves_like 'scrolling loads remaining batches'
          end

          context 'and the target node is in the second batch' do
            let(:batch_target) { 1 }
            let(:expected_node_count_on_page_load) { 90 }
            let(:expected_populated_batches) { [0, 1, 2] }
            let(:expected_batch_placeholders) { [3] }
            let(:node_position) { 45 }

            it_behaves_like 'basic details of uri fragment batch rendering'
            it_behaves_like 'loading the first batch'
            it_behaves_like 'loading middle batches'
            it_behaves_like 'including placeholders for non-loaded batches'
            it_behaves_like 'including the last batch placeholder'
            it_behaves_like 'scrolling loads remaining batches'
          end

          context 'and the target node is in the third batch' do
            let(:batch_target) { 2 }
            let(:expected_node_count_on_page_load) { 91 }
            let(:expected_populated_batches) { [0, 1, 2, 3] }
            let(:expected_batch_placeholders) { [] }
            let(:node_position) { 75 }

            it_behaves_like 'basic details of uri fragment batch rendering'
            it_behaves_like 'loading the first batch'
            it_behaves_like 'loading middle batches'
            it_behaves_like 'loading the last batch'
            it_behaves_like 'having all nodes loaded'
          end

          context 'and the target node is in the fourth batch' do
            let(:batch_target) { 3 }
            let(:expected_node_count_on_page_load) { 61 }
            let(:expected_populated_batches) { [0, 2, 3] }
            let(:expected_batch_placeholders) { [1] }
            let(:node_position) { 91 }

            it_behaves_like 'basic details of uri fragment batch rendering'
            it_behaves_like 'loading the first batch'
            it_behaves_like 'loading middle batches'
            it_behaves_like 'loading the last batch'
            it_behaves_like 'including placeholders for non-loaded batches'
            it_behaves_like 'scrolling loads remaining batches'
          end
        end
      end

      context 'when the target node is the root node' do
        let!(:node) do
          visit "/repositories/#{@repo.id}/resources/#{resource_id}/collection_organization#tree::resource_#{resource_id}"
          wait_for_jquery

          find(".infinite-tree .root.current")
        end

        let(:parent_list) { node.find('& > .node-children') }

        context 'when the root node has 1 batch of child nodes' do
          let(:resource_id) { @resource.id }
          let(:total_nodes) { 7 }
          let(:expected_node_count_on_page_load) { 7 }

          it_behaves_like 'basic details of uri fragment batch rendering'
          it_behaves_like 'having all nodes loaded'
        end

        context 'when the root node has 2 batches of child nodes' do
          let(:resource_id) { @resource2.id }
          let(:total_nodes) { 31 }
          let(:parent) { 'resource2' }
          let(:expected_node_count_on_page_load) { 30 }
          let(:expected_batch_placeholders) { [1] }

          it_behaves_like 'basic details of uri fragment batch rendering'
          it_behaves_like 'loading the first batch'
          it_behaves_like 'scrolling loads remaining batches'
        end

        context 'when the root node has 3 batches of child nodes' do
          let(:resource_id) { @resource3.id }
          let(:total_nodes) { 61 }
          let(:parent) { 'resource3' }
          let(:expected_node_count_on_page_load) { 30 }
          let(:expected_batch_placeholders) { [1, 2] }

          it_behaves_like 'basic details of uri fragment batch rendering'
          it_behaves_like 'loading the first batch'
          it_behaves_like 'scrolling loads remaining batches'
        end
      end
    end
  end
end
