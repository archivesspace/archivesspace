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

      @ao1_of_ao8 = create(:archival_object, # 1 batch
        resource: {'ref' => @resource.uri},
        parent: {'ref' => @ao8.uri},
        publish: true
      )

      run_indexers
    end

    shared_examples 'uri fragment batch rendering' do |parent, batch_target, expected_populated_batches, expected_batch_placeholders|
      before(:each) do
        @total_nodes = case parent
                       when 'ao3' then 120
                       when 'ao4' then 81
                       when 'ao5' then 61
                       when 'ao6' then 41
                       when 'ao7' then 21
                       when 'ao8' then 1
                       end
        @total_batches = (@total_nodes / @tree_batch_size.to_f).ceil
        @expected_node_count_on_page_load = expected_populated_batches.sum do |batch|
          if batch == (@total_nodes / @tree_batch_size.to_f).ceil - 1
            @total_nodes % @tree_batch_size == 0 ? @tree_batch_size : @total_nodes % @tree_batch_size
          else
            @tree_batch_size
          end
        end
        node_position = if batch_target == (@total_nodes / @tree_batch_size.to_f).ceil - 1 && (@total_nodes % @tree_batch_size) == 1
                          @total_nodes
                        else
                          (batch_target * @tree_batch_size) + (@tree_batch_size / 2)
                        end
        node_var = "@ao#{node_position}_of_#{parent}"
        @node_record_id = instance_variable_get(node_var).id

        visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization#tree::archival_object_#{@node_record_id}"
        wait_for_jquery

        @node = find("#archival_object_#{@node_record_id}.current")
        @parent_list = @node.find(:xpath, '..')
      end

      it 'shows the child node of interest' do
        def node_in_tree_viewport?(node)
          tree = find('#infinite-tree-container')
          tree_rect = page.evaluate_script('arguments[0].getBoundingClientRect()', tree)
          node_rect = page.evaluate_script('arguments[0].getBoundingClientRect()', node)
          node_top_in_view = node_rect['top'] >= tree_rect['top'] && node_rect['top'] <= tree_rect['bottom']
          node_bottom_in_view = node_rect['bottom'] >= tree_rect['top'] && node_rect['bottom'] <= tree_rect['bottom']

          node_top_in_view && node_bottom_in_view
        end

        expect(node_in_tree_viewport?(@node)).to be true
      end

      it 'loads the correct number of sibling nodes' do
        expect(@parent_list).to have_css('.node', count: @expected_node_count_on_page_load)
      end

      it 'loads content in the correct order' do
        if @total_batches == 1
          (1..@total_nodes).each do |node_num|
            if @total_nodes == 1
              expect(@parent_list).to have_css("#archival_object_#{@node_record_id}")
            else
              curr_node_id = instance_variable_get("@ao#{node_num}_of_#{parent}").id

              if node_num == 1
                expect(@parent_list).to have_css("& #archival_object_#{@node_record_id}:first-child")
              elsif node_num < @total_nodes
                next_node_id = instance_variable_get("@ao#{node_num + 1}_of_#{parent}").id
                expect(@parent_list).to have_css("#archival_object_#{curr_node_id} + #archival_object_#{next_node_id}")
              else
                prev_node_id = instance_variable_get("@ao#{node_num - 1}_of_#{parent}").id
                expect(@parent_list).to have_css("#archival_object_#{prev_node_id} + #archival_object_#{curr_node_id}")
                expect(@parent_list).to have_css("& #archival_object_#{curr_node_id}:last-child")
              end
            end
          end

          expect(@parent_list).to_not have_css('[data-batch-placeholder]')
        else
          all_batches = (expected_populated_batches + expected_batch_placeholders).sort

          all_batches.each do |batch_offset|
            if batch_offset == 0
              (1..@tree_batch_size).each do |node_num|
                curr_node_id = instance_variable_get("@ao#{node_num}_of_#{parent}").id
                if node_num == 1
                  expect(@parent_list).to have_css("& #archival_object_#{curr_node_id}:first-child")
                elsif node_num < @tree_batch_size
                  next_node_id = instance_variable_get("@ao#{node_num + 1}_of_#{parent}").id
                  expect(@parent_list).to have_css("#archival_object_#{curr_node_id} + #archival_object_#{next_node_id}")
                else
                  prev_node_id = instance_variable_get("@ao#{node_num - 1}_of_#{parent}").id
                  expect(@parent_list).to have_css("#archival_object_#{prev_node_id} + #archival_object_#{curr_node_id}")
                end
              end
            elsif expected_populated_batches.include?(batch_offset)
              prev_batch_was_populated = expected_populated_batches.include?(batch_offset - 1)
              curr_batch_first_node_id = instance_variable_get("@ao#{batch_offset * @tree_batch_size + 1}_of_#{parent}").id

              if prev_batch_was_populated
                prev_batch_last_node_id = instance_variable_get("@ao#{batch_offset * @tree_batch_size}_of_#{parent}").id
                expect(@parent_list).to have_css("#archival_object_#{prev_batch_last_node_id} + #archival_object_#{curr_batch_first_node_id}")
              else
                expect(@parent_list).to have_css("[data-batch-placeholder='#{batch_offset - 1}'] + #archival_object_#{curr_batch_first_node_id}", visible: :all)
              end

              if batch_offset < @total_batches - 1 # not last batch
                (batch_offset * @tree_batch_size + 1..(batch_offset + 1) * @tree_batch_size).each do |node_num|
                  curr_node_id = instance_variable_get("@ao#{node_num}_of_#{parent}").id

                  if node_num < (batch_offset + 1) * @tree_batch_size # not last node in this batch
                    next_node_id = instance_variable_get("@ao#{node_num + 1}_of_#{parent}").id
                    expect(@parent_list).to have_css("#archival_object_#{curr_node_id} + #archival_object_#{next_node_id}")
                  else # last node in this batch
                    prev_node_id = instance_variable_get("@ao#{node_num - 1}_of_#{parent}").id
                    expect(@parent_list).to have_css("#archival_object_#{prev_node_id} + #archival_object_#{curr_node_id}")
                  end
                end
              else # last batch
                second_to_last_batch_last_node_id = instance_variable_get("@ao#{batch_offset * @tree_batch_size}_of_#{parent}").id
                last_batch_first_node_position = batch_offset * @tree_batch_size + 1
                last_batch_first_node_id = instance_variable_get("@ao#{last_batch_first_node_position}_of_#{parent}").id
                expect(@parent_list).to have_css("#archival_object_#{second_to_last_batch_last_node_id} + #archival_object_#{last_batch_first_node_id}")

                if last_batch_first_node_position < @total_nodes # not last node in this batch
                  (last_batch_first_node_position..@total_nodes).each do |node_num|
                    curr_node_id = instance_variable_get("@ao#{node_num}_of_#{parent}").id
                    if node_num < @total_nodes # not last node in this batch
                      next_node_id = instance_variable_get("@ao#{node_num + 1}_of_#{parent}").id
                      expect(@parent_list).to have_css("#archival_object_#{curr_node_id} + #archival_object_#{next_node_id}")
                    else
                      prev_node_id = instance_variable_get("@ao#{node_num - 1}_of_#{parent}").id
                      expect(@parent_list).to have_css("#archival_object_#{prev_node_id} + #archival_object_#{curr_node_id}")
                      expect(@parent_list).to have_css("& #archival_object_#{curr_node_id}:last-child")
                    end
                  end
                end
              end
            elsif expected_batch_placeholders.include?(batch_offset)
              prev_batch_was_populated = expected_populated_batches.include?(batch_offset - 1)

              if prev_batch_was_populated
                prev_batch_last_node_id = instance_variable_get("@ao#{batch_offset * @tree_batch_size}_of_#{parent}").id
                expect(@parent_list).to have_css("#archival_object_#{prev_batch_last_node_id} + [data-batch-placeholder='#{batch_offset}']", visible: :all)
              else
                expect(@parent_list).to have_css("[data-batch-placeholder='#{batch_offset - 1}'] + [data-batch-placeholder='#{batch_offset}']", visible: false)
              end

              if batch_offset == @total_batches - 1
                expect(@parent_list).to have_css("& [data-batch-placeholder='#{batch_offset}']:last-child", visible: :all)
              end
            end
          end
        end
      end

      it 'fetches remaining siblings on scroll' do
        if expected_batch_placeholders.any?
          container = page.find('#infinite-tree-container')

          expected_batch_placeholders.each do |batch_offset|
            wait_for_jquery
            observer_node = @parent_list.first("[data-observe-offset='#{batch_offset}']")
            container.scroll_to(observer_node, align: :center)
          end
        end

        wait_for_jquery
        expect(@parent_list).to have_css('.node', count: @total_nodes)
        expect(@parent_list).not_to have_css('[data-batch-placeholder]', visible: false)
      end
    end

    context 'when loading a page with a URI fragment' do
      describe 'should load the correct content' do
        it_behaves_like 'uri fragment batch rendering', 'ao3', 0, [0, 1],       [2, 3, 4, 5]
        it_behaves_like 'uri fragment batch rendering', 'ao3', 1, [0, 1, 2],    [3, 4, 5]
        it_behaves_like 'uri fragment batch rendering', 'ao3', 2, [0, 1, 2, 3], [4, 5]
        it_behaves_like 'uri fragment batch rendering', 'ao3', 3, [0, 2, 3, 4], [1, 5]
        it_behaves_like 'uri fragment batch rendering', 'ao3', 4, [0, 3, 4, 5], [1, 2]
        it_behaves_like 'uri fragment batch rendering', 'ao3', 5, [0, 4, 5],    [1, 2, 3]

        it_behaves_like 'uri fragment batch rendering', 'ao4', 0, [0, 1],       [2, 3, 4]
        it_behaves_like 'uri fragment batch rendering', 'ao4', 1, [0, 1, 2],    [3, 4]
        it_behaves_like 'uri fragment batch rendering', 'ao4', 2, [0, 1, 2, 3], [4]
        it_behaves_like 'uri fragment batch rendering', 'ao4', 3, [0, 2, 3, 4], [1]
        it_behaves_like 'uri fragment batch rendering', 'ao4', 4, [0, 3, 4],    [1, 2]

        it_behaves_like 'uri fragment batch rendering', 'ao5', 0, [0, 1],       [2, 3]
        it_behaves_like 'uri fragment batch rendering', 'ao5', 1, [0, 1, 2],    [3]
        it_behaves_like 'uri fragment batch rendering', 'ao5', 2, [0, 1, 2, 3], []
        it_behaves_like 'uri fragment batch rendering', 'ao5', 3, [0, 2, 3],    [1]

        it_behaves_like 'uri fragment batch rendering', 'ao6', 0, [0, 1],       [2]
        it_behaves_like 'uri fragment batch rendering', 'ao6', 1, [0, 1, 2],    []
        it_behaves_like 'uri fragment batch rendering', 'ao6', 2, [0, 1, 2],    []

        it_behaves_like 'uri fragment batch rendering', 'ao7', 0, [0, 1],       []
        it_behaves_like 'uri fragment batch rendering', 'ao7', 1, [0, 1],       []

        it_behaves_like 'uri fragment batch rendering', 'ao8', 0, [0],          []
      end
    end
  end
end
