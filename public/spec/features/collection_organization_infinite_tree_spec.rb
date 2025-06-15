require 'spec_helper'
require 'rails_helper'

describe 'Collection Organization', js: true do
  before(:all) do
    @repo = create(:repo, repo_code: "collection_organization_test_#{Time.now.to_i}")
    set_repo(@repo)

    @tree_batch_size = Rails.configuration.infinite_tree_waypoint_size
  end

  describe 'InfiniteTree' do
    before(:all) do
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
      @ao8 = create(:archival_object,
        resource: {'ref' => @resource.uri},
        publish: true
      )
      @ao9 = create(:archival_object,
         resource: {'ref' => @resource.uri},
         publish: true
       )

      120.times do |i| # 6 batches
        # Why 120 and not 101?
        # Flaky batch rendering tests were observed with 101 nodes, where an extra batch
        # sometimes got loaded right after initial page load via the InfiniteTree batchObserver.
        # The workaround is a full last batch, and to select its middle node for the URI fragment.
        instance_variable_set("@ao#{i + 1}_of_ao3", create(:archival_object,
          resource: {'ref' => @resource.uri},
          parent: {'ref' => @ao3.uri},
          publish: true
        ))
      end

      81.times do |i| # 5 batches
        instance_variable_set("@ao#{i + 1}_of_ao4", create(:archival_object,
          resource: {'ref' => @resource.uri},
          parent: {'ref' => @ao4.uri},
          publish: true
        ))
      end

      61.times do |i| # 4 batches
        instance_variable_set("@ao#{i + 1}_of_ao5", create(:archival_object,
          resource: {'ref' => @resource.uri},
          parent: {'ref' => @ao5.uri},
          publish: true
        ))
      end

      41.times do |i| # 3 batches
        instance_variable_set("@ao#{i + 1}_of_ao6", create(:archival_object,
          resource: {'ref' => @resource.uri},
          parent: {'ref' => @ao6.uri},
          publish: true
        ))
      end

      21.times do |i| # 2 batches
        instance_variable_set("@ao#{i + 1}_of_ao7", create(:archival_object,
          resource: {'ref' => @resource.uri},
          parent: {'ref' => @ao7.uri},
          publish: true
        ))
      end

      @ao1_of_ao8 = create(:archival_object, # 1 batch with a single node
        resource: {'ref' => @resource.uri},
        parent: {'ref' => @ao8.uri},
        publish: true
      )

      5.times do |i| # 1 batch with multiple nodes
        instance_variable_set("@ao#{i + 1}_of_ao9", create(:archival_object,
          resource: {'ref' => @resource.uri},
          parent: {'ref' => @ao9.uri},
          publish: true
        ))
      end

      run_indexers
    end

    RSpec::Matchers.define :appear_in_tree_vieport do
      match do |node|
        tree = find('#infinite-tree-container')
        tree_rect = page.evaluate_script('arguments[0].getBoundingClientRect()', tree)
        node_rect = page.evaluate_script('arguments[0].getBoundingClientRect()', node)
        node_top_in_view = node_rect['top'] >= tree_rect['top'] && node_rect['top'] <= tree_rect['bottom']
        node_bottom_in_view = node_rect['bottom'] >= tree_rect['top'] && node_rect['bottom'] <= tree_rect['bottom']

        node_top_in_view && node_bottom_in_view
      end
    end

    shared_examples 'uri fragment batch rendering' do
      it 'shows the child node of interest' do
        expect(node).to appear_in_tree_vieport
      end

      it 'loads the correct number of sibling nodes' do
        expect(parent_list).to have_css('.node', count: expected_node_count_on_page_load)
      end
    end

    shared_examples 'having all nodes loaded' do
      it 'has all siblings already loaded' do
        wait_for_jquery
        expect(parent_list).to have_css('.node', count: total_nodes)
        expect(parent_list).not_to have_css('[data-batch-placeholder]', visible: false)
      end
    end

    shared_examples 'scrolling loads remaining nodes' do
      it 'fetches remaining siblings on scroll' do
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

    shared_examples 'loading first batch of multi-batch content' do
      it 'contains the first batch (offset: 0)' do
        aggregate_failures 'does not contain a data batch placeholder' do
          expect(parent_list).to_not have_css('[data-batch-placeholder]')
        end

        aggregate_failures 'includes the first node of the batch' do
          curr_node_id = instance_variable_get("@ao1_of_#{parent}").id
          expect(parent_list).to have_css("& #archival_object_#{curr_node_id}:first-child")
        end

        aggregate_failures 'includes the intermediate nodes of the batch' do
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

    shared_examples 'loading multi-batch content in the correct order' do
      it 'loads content in the correct order' do
        all_batches = (expected_populated_batches + expected_batch_placeholders).sort

        all_batches.each do |batch_offset|
          if expected_populated_batches.include?(batch_offset) && batch_offset > 0
            prev_batch_was_populated = expected_populated_batches.include?(batch_offset - 1)
            curr_batch_first_node_id = instance_variable_get("@ao#{batch_offset * @tree_batch_size + 1}_of_#{parent}").id

            if prev_batch_was_populated
              prev_batch_last_node_id = instance_variable_get("@ao#{batch_offset * @tree_batch_size}_of_#{parent}").id
              expect(parent_list).to have_css("#archival_object_#{prev_batch_last_node_id} + #archival_object_#{curr_batch_first_node_id}")
            else
              expect(parent_list).to have_css("[data-batch-placeholder='#{batch_offset - 1}'] + #archival_object_#{curr_batch_first_node_id}", visible: :all)
            end

            if batch_offset < total_batches - 1 # not last batch
              (batch_offset * @tree_batch_size + 1..(batch_offset + 1) * @tree_batch_size).each do |node_num|
                curr_node_id = instance_variable_get("@ao#{node_num}_of_#{parent}").id

                if node_num < (batch_offset + 1) * @tree_batch_size # not last node in this batch
                  next_node_id = instance_variable_get("@ao#{node_num + 1}_of_#{parent}").id

                  expect(parent_list).to have_css("#archival_object_#{curr_node_id} + #archival_object_#{next_node_id}")
                else # last node in this batch
                  prev_node_id = instance_variable_get("@ao#{node_num - 1}_of_#{parent}").id
                  expect(parent_list).to have_css("#archival_object_#{prev_node_id} + #archival_object_#{curr_node_id}")
                end
              end
            else # last batch
              second_to_last_batch_last_node_id = instance_variable_get("@ao#{batch_offset * @tree_batch_size}_of_#{parent}").id
              last_batch_first_node_position = batch_offset * @tree_batch_size + 1
              last_batch_first_node_id = instance_variable_get("@ao#{last_batch_first_node_position}_of_#{parent}").id
              expect(parent_list).to have_css("#archival_object_#{second_to_last_batch_last_node_id} + #archival_object_#{last_batch_first_node_id}")

              if last_batch_first_node_position < total_nodes # not last node in this batch
                (last_batch_first_node_position..total_nodes).each do |node_num|
                  curr_node_id = instance_variable_get("@ao#{node_num}_of_#{parent}").id
                  if node_num < total_nodes # not last node in this batch
                    next_node_id = instance_variable_get("@ao#{node_num + 1}_of_#{parent}").id
                    expect(parent_list).to have_css("#archival_object_#{curr_node_id} + #archival_object_#{next_node_id}")
                  else
                    prev_node_id = instance_variable_get("@ao#{node_num - 1}_of_#{parent}").id
                    expect(parent_list).to have_css("#archival_object_#{prev_node_id} + #archival_object_#{curr_node_id}")
                    expect(parent_list).to have_css("& #archival_object_#{curr_node_id}:last-child")
                  end
                end
              end
            end
          elsif expected_batch_placeholders.include?(batch_offset)
            prev_batch_was_populated = expected_populated_batches.include?(batch_offset - 1)

            if prev_batch_was_populated
              prev_batch_last_node_id = instance_variable_get("@ao#{batch_offset * @tree_batch_size}_of_#{parent}").id
              expect(parent_list).to have_css("#archival_object_#{prev_batch_last_node_id} + [data-batch-placeholder='#{batch_offset}']", visible: :all)
            else
              expect(parent_list).to have_css("[data-batch-placeholder='#{batch_offset - 1}'] + [data-batch-placeholder='#{batch_offset}']", visible: false)
            end

            if batch_offset == total_batches - 1
              expect(parent_list).to have_css("& [data-batch-placeholder='#{batch_offset}']:last-child", visible: :all)
            end
          end
        end
      end
    end

    context 'when loading a page with a URI fragment' do
      let(:total_batches) { (total_nodes / @tree_batch_size.to_f).ceil }

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

      context 'showing a tree with 6 batches of child nodes' do
        # Why 120 and not 101?
        # Flaky batch rendering tests were observed with 101 nodes, where an extra batch
        # sometimes got loaded right after initial page load via the InfiniteTree batchObserver.
        # The workaround is a full last batch, and to select its middle node for the URI fragment.
        let(:total_nodes) { 120 }
        let(:parent) { 'ao3' }

        context 'and the target node is in the first batch' do
          let(:batch_target) { 0 }
          let(:expected_populated_batches) { [0, 1] }
          let(:expected_batch_placeholders) { [2, 3, 4, 5] }
          let(:expected_node_count_on_page_load) { 40 }
          let(:node_position) { 10 }

          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'loading first batch of multi-batch content'

          it_behaves_like 'scrolling loads remaining nodes'

          it_behaves_like 'loading multi-batch content in the correct order'
        end

        context 'and the target node is in the second batch' do
          let(:batch_target) { 1 }
          let(:expected_populated_batches) { [0, 1, 2] }
          let(:expected_batch_placeholders) { [3, 4, 5] }
          let(:expected_node_count_on_page_load) { 60 }
          let(:node_position) { 30 }

          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'loading first batch of multi-batch content'

          it_behaves_like 'scrolling loads remaining nodes'

          it_behaves_like 'loading multi-batch content in the correct order'
        end

        context 'and the target node is in the third batch' do
          let(:batch_target) { 2 }
          let(:expected_populated_batches) { [0, 1, 2, 3] }
          let(:expected_batch_placeholders) { [4, 5] }
          let(:expected_node_count_on_page_load) { 80 }
          let(:node_position) { 50 }


          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'loading first batch of multi-batch content'

          it_behaves_like 'scrolling loads remaining nodes'

          it_behaves_like 'loading multi-batch content in the correct order'
        end

        context 'and the target node is in the forth batch' do
          let(:batch_target) { 3 }
          let(:expected_populated_batches) { [0, 2, 3, 4] }
          let(:expected_batch_placeholders) { [1, 5] }
          let(:expected_node_count_on_page_load) { 80 }
          let(:node_position) { 70 }

          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'loading first batch of multi-batch content'

          it_behaves_like 'scrolling loads remaining nodes'

          it_behaves_like 'loading multi-batch content in the correct order'
        end

        context 'and the target node is in the fifth batch' do
          let(:batch_target) { 4 }
          let(:expected_populated_batches) { [0, 3, 4, 5] }
          let(:expected_batch_placeholders) { [1, 2] }
          let(:expected_node_count_on_page_load) { 80 }
          let(:node_position) { 90 }

          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'loading first batch of multi-batch content'

          it_behaves_like 'scrolling loads remaining nodes'

          it_behaves_like 'loading multi-batch content in the correct order'
        end

        context 'and the target node is in the sixth batch' do
          let(:batch_target) { 5 }
          let(:expected_populated_batches) { [0, 4, 5] }
          let(:expected_batch_placeholders) { [1, 2, 3] }
          let(:expected_node_count_on_page_load) { 60 }
          let(:node_position) { 110 }


          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'loading first batch of multi-batch content'

          it_behaves_like 'scrolling loads remaining nodes'

          it_behaves_like 'loading multi-batch content in the correct order'
        end
      end

      context 'showing a tree with 5 batches of child nodes' do
        let(:total_nodes) { 81 }
        let(:parent) { 'ao4' }

        context 'and the target node is in the first batch' do
          let(:batch_target) { 0 }
          let(:expected_populated_batches) { [0, 1] }
          let(:expected_batch_placeholders) { [2, 3, 4] }
          let(:expected_node_count_on_page_load) { 40 }
          let(:node_position) { 10 }

          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'loading first batch of multi-batch content'

          it_behaves_like 'scrolling loads remaining nodes'

          it_behaves_like 'loading multi-batch content in the correct order'
        end

        context 'and the target node is in the second batch' do
          let(:batch_target) { 1 }
          let(:expected_populated_batches) { [0, 1, 2] }
          let(:expected_batch_placeholders) { [3, 4] }
          let(:expected_node_count_on_page_load) { 60 }
          let(:node_position) { 30 }

          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'loading first batch of multi-batch content'

          it_behaves_like 'scrolling loads remaining nodes'

          it_behaves_like 'loading multi-batch content in the correct order'
        end

        context 'and the target node is in the third batch' do
          let(:batch_target) { 2 }
          let(:expected_populated_batches) { [0, 1, 2, 3] }
          let(:expected_batch_placeholders) { [4] }
          let(:expected_node_count_on_page_load) { 80 }
          let(:node_position) { 50 }

          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'loading first batch of multi-batch content'

          it_behaves_like 'scrolling loads remaining nodes'

          it_behaves_like 'loading multi-batch content in the correct order'
        end

        context 'and the target node is in the forth batch' do
          let(:batch_target) { 3 }
          let(:expected_populated_batches) { [0, 2, 3, 4] }
          let(:expected_batch_placeholders) { [1] }
          let(:expected_node_count_on_page_load) { 61 }
          let(:node_position) { 70 }

          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'loading first batch of multi-batch content'

          it_behaves_like 'scrolling loads remaining nodes'

          it_behaves_like 'loading multi-batch content in the correct order'
        end

        context 'and the target node is in the fifth batch' do
          let(:batch_target) { 4 }
          let(:expected_populated_batches) { [0, 3, 4] }
          let(:expected_batch_placeholders) { [1, 2] }
          let(:expected_node_count_on_page_load) { 41 }
          let(:node_position) { 81 }

          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'loading first batch of multi-batch content'

          it_behaves_like 'scrolling loads remaining nodes'

          it_behaves_like 'loading multi-batch content in the correct order'
        end
      end

      context 'showing a tree with 4 batches of child nodes' do
        let(:total_nodes) { 61 }
        let(:parent) { 'ao5' }

        context 'and the target node is in the first batch' do
          let(:batch_target) { 0 }
          let(:expected_populated_batches) { [0, 1] }
          let(:expected_batch_placeholders) { [2, 3] }
          let(:node_position) { 10 }
          let(:expected_node_count_on_page_load) { 40 }

          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'loading first batch of multi-batch content'

          it_behaves_like 'scrolling loads remaining nodes'

          it_behaves_like 'loading multi-batch content in the correct order'
        end

        context 'and the target node is in the second batch' do
          let(:batch_target) { 1 }
          let(:expected_populated_batches) { [0, 1, 2] }
          let(:expected_batch_placeholders) { [3] }
          let(:node_position) { 30 }
          let(:expected_node_count_on_page_load) { 60 }

          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'loading first batch of multi-batch content'

          it_behaves_like 'scrolling loads remaining nodes'

          it_behaves_like 'loading multi-batch content in the correct order'
        end

        context 'and the target node is in the third batch' do
          let(:batch_target) { 2 }
          let(:expected_populated_batches) { [0, 1, 2, 3] }
          let(:expected_batch_placeholders) { [] }
          let(:node_position) { 50 }
          let(:expected_node_count_on_page_load) { 61 }

          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'loading first batch of multi-batch content'

          it_behaves_like 'having all nodes loaded'

          it_behaves_like 'loading multi-batch content in the correct order'
        end

        context 'and the target node is in the forth batch' do
          let(:batch_target) { 3 }
          let(:expected_populated_batches) { [0, 2, 3] }
          let(:expected_batch_placeholders) { [1] }
          let(:node_position) { 61 }
          let(:expected_node_count_on_page_load) { 41 }

          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'loading first batch of multi-batch content'

          it_behaves_like 'scrolling loads remaining nodes'

          it_behaves_like 'loading multi-batch content in the correct order'
        end
      end

      context 'showing a tree with 3 batches of child nodes' do
        let(:total_nodes) { 41 }
        let(:parent) { 'ao6' }

        context 'and the target node is in the first batch' do
          let(:batch_target) { 0 }
          let(:expected_populated_batches) { [0, 1] }
          let(:expected_batch_placeholders) { [2] }
          let(:node_position) { 10 }
          let(:expected_node_count_on_page_load) { 40 }

          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'loading first batch of multi-batch content'

          it_behaves_like 'scrolling loads remaining nodes'

          it_behaves_like 'loading multi-batch content in the correct order'
        end

        context 'and the target node is in the second batch' do
          let(:batch_target) { 1 }
          let(:expected_populated_batches) { [0, 1, 2] }
          let(:expected_batch_placeholders) { [] }
          let(:node_position) { 30 }
          let(:expected_node_count_on_page_load) { 41 }

          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'loading first batch of multi-batch content'

          it_behaves_like 'having all nodes loaded'

          it_behaves_like 'loading multi-batch content in the correct order'
        end

        context 'and the target node is in the third batch' do
          let(:batch_target) { 2 }
          let(:expected_populated_batches) { [0, 1, 2] }
          let(:expected_batch_placeholders) { [] }
          let(:node_position) { 41 }
          let(:expected_node_count_on_page_load) { 41 }

          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'loading first batch of multi-batch content'

          it_behaves_like 'having all nodes loaded'

          it_behaves_like 'loading multi-batch content in the correct order'
        end
      end

      context 'showing a tree with 2 batches of child nodes' do
        let(:total_nodes) { 21 }
        let(:parent) { 'ao7' }

        context 'and the target node is in the first batch' do
          let(:batch_target) { 0 }
          let(:expected_populated_batches) { [0, 1] }
          let(:expected_batch_placeholders) { [] }
          let(:node_position) { 10 }
          let(:expected_node_count_on_page_load) { 21 }

          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'loading first batch of multi-batch content'

          it_behaves_like 'having all nodes loaded'

          it_behaves_like 'loading multi-batch content in the correct order'
        end

        context 'and the target node is in the second batch' do
          let(:batch_target) { 1 }
          let(:expected_populated_batches) { [0, 1] }
          let(:expected_batch_placeholders) { [] }
          let(:node_position) { 21 }
          let(:expected_node_count_on_page_load) { 21 }

          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'loading first batch of multi-batch content'

          it_behaves_like 'having all nodes loaded'

          it_behaves_like 'loading multi-batch content in the correct order'
        end
      end

      context 'showing a tree with 1 batch' do
        context 'containing a single node' do
          let(:total_nodes) { 1 }
          let(:parent) { 'ao8' }
          let(:batch_target) { 0 }
          let(:expected_populated_batches) { [0] }
          let(:expected_batch_placeholders) { [] }
          let(:expected_node_count_on_page_load) { 1 }
          let(:node_position) { 1 }

          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'having all nodes loaded'

          describe 'the parent list' do
            it 'contains the node' do
              aggregate_failures 'does not contain a data batch placeholder' do
                expect(parent_list).to_not have_css('[data-batch-placeholder]')
              end

              aggregate_failures 'loads the node' do
                expect(parent_list).to have_css("#archival_object_#{node_record_id}")
              end
            end
          end
        end

        context 'containing multiple nodes' do
          let(:total_nodes) { 5 }
          let(:parent) { 'ao9' }
          let(:batch_target) { 0 }
          let(:expected_populated_batches) { [0] }
          let(:expected_batch_placeholders) { [] }
          let(:expected_node_count_on_page_load) { 5 }
          let(:node_position) { 2 }

          it_behaves_like 'uri fragment batch rendering'

          it_behaves_like 'having all nodes loaded'

          describe 'the parent list' do
            it 'contains the first batch (offset: 0)' do
              aggregate_failures 'does not contain a data batch placeholder' do
                expect(parent_list).to_not have_css('[data-batch-placeholder]')
              end

              aggregate_failures 'includes the first node of the batch' do
                curr_node_id = instance_variable_get("@ao1_of_#{parent}").id
                expect(parent_list).to have_css("& #archival_object_#{curr_node_id}:first-child")
              end

              aggregate_failures 'includes the intermediate nodes of the batch' do
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
    end
  end
end
