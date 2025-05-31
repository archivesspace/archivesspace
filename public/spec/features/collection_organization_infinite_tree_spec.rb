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

      120.times do |i| # 6 batches
        # Why 120 and not 101?
        # Flaky batch rendering tests were observed with 101 nodes, where an extra batch
        # sometimes got loaded right after initial page load via the InfiniteTree batchObserver.
        # The workaround is a full last batch, and to select its middle node for the URI fragment.
        instance_variable_set("@ao#{i + 1}_of_ao7", create(:archival_object,
          resource: {'ref' => @resource.uri},
          parent: {'ref' => @ao7.uri},
          publish: true
        ))
      end

      81.times do |i| # 5 batches
        instance_variable_set("@ao#{i + 1}_of_ao3", create(:archival_object,
          resource: {'ref' => @resource.uri},
          parent: {'ref' => @ao3.uri},
          publish: true
        ))
      end

      41.times do |i| # 3 batches
        instance_variable_set("@ao#{i + 1}_of_ao4", create(:archival_object,
          resource: {'ref' => @resource.uri},
          parent: {'ref' => @ao4.uri},
          publish: true
        ))
      end

      21.times do |i| # 2 batches
        instance_variable_set("@ao#{i + 1}_of_ao5", create(:archival_object,
          resource: {'ref' => @resource.uri},
          parent: {'ref' => @ao5.uri},
          publish: true
        ))
      end

      @ao1_of_ao6 = create(:archival_object, # 1 batch
        resource: {'ref' => @resource.uri},
        parent: {'ref' => @ao6.uri},
        publish: true
      )

      run_indexers
    end

    shared_examples 'uri fragment batch rendering' do |parent, batch_offset|
      before(:each) do
        total_nodes = case parent
                      when 'ao7' then 120
                      when 'ao3' then 81
                      when 'ao4' then 41
                      when 'ao5' then 21
                      when 'ao6' then 1
                      end
        @total_batches = (total_nodes / @tree_batch_size.to_f).ceil
        node_position = if batch_offset == @total_batches - 1 && (total_nodes % @tree_batch_size) == 1
                          total_nodes
                        else
                          (batch_offset * @tree_batch_size) + (@tree_batch_size / 2)
                        end
        node_var = "@ao#{node_position}_of_#{parent}"
        @expected_node_count = case batch_offset
                               when 0
                                 if @total_batches < 3
                                   total_nodes
                                 else
                                   @tree_batch_size * 2
                                 end
                               when @total_batches - 1
                                 if @total_batches <= 3
                                   total_nodes
                                 else
                                   @tree_batch_size * 2 + (total_nodes % @tree_batch_size == 0 ? @tree_batch_size : total_nodes % @tree_batch_size)
                                 end
                               else
                                 if @total_batches < 4
                                   total_nodes
                                 else
                                   case batch_offset
                                   when 1
                                     @tree_batch_size * 3
                                   when @total_batches - 2
                                     @tree_batch_size * 3 + (total_nodes % @tree_batch_size == 0 ? @tree_batch_size : total_nodes % @tree_batch_size)
                                   else
                                     @tree_batch_size * 4
                                   end
                                 end
                               end
        @batch_placeholders_arr = case batch_offset
                                  when 0 then (2..@total_batches - 1).to_a
                                  when @total_batches - 1 then (1..@total_batches - 3).to_a
                                  else
                                    (1..batch_offset - 2).to_a + (batch_offset + 2..@total_batches - 1).to_a
                                  end

        visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization#tree::archival_object_#{instance_variable_get(node_var).id}"
        wait_for_jquery
        node = find("#archival_object_#{instance_variable_get(node_var).id}.current")
        @parent_list = node.find(:xpath, '..')
      end

      it "loads the correct number of siblings" do
        expect(@parent_list).to have_css('.node', count: @expected_node_count)
      end

      it 'loads the correct batch placeholders' do
        if @batch_placeholders_arr.length > 0
          expect(@parent_list).to have_css('[data-batch-placeholder]', count: @batch_placeholders_arr.length, visible: false)

          case batch_offset
          when 0 # Batches loaded: 0, 1
            last_node_selector = "#archival_object_#{instance_variable_get("@ao40_of_#{parent}").id}"
            expect(@parent_list).to have_css("#archival_object_#{instance_variable_get("@ao40_of_#{parent}").id} + [data-batch-placeholder='2']", visible: false)
            if @batch_placeholders_arr.length > 1
              @batch_placeholders_arr.each_cons(2) do |prev, curr|
                expect(@parent_list).to have_css("[data-batch-placeholder='#{prev}'] + [data-batch-placeholder='#{curr}']", visible: false)
              end
            end
          when @total_batches - 1 # Batches loaded: 0, n-2, n-1
            expect(@parent_list).to have_css("#archival_object_#{instance_variable_get("@ao20_of_#{parent}").id} + [data-batch-placeholder='1']", visible: false)
            expect(@parent_list).to have_css("[data-batch-placeholder='#{@batch_placeholders_arr.last}'] + #archival_object_#{instance_variable_get("@ao#{(batch_offset - 1) * @tree_batch_size + 1}_of_#{parent}").id}", visible: :all)
            if @batch_placeholders_arr.length > 1
              @batch_placeholders_arr.each_cons(2) do |prev, curr|
                expect(@parent_list).to have_css("[data-batch-placeholder='#{prev}'] + [data-batch-placeholder='#{curr}']", visible: false)
              end
            end
          else # Batches loaded: 0, n-1, n, n+1
            if batch_offset < 3
              last_node_number = batch_offset == 1 ? '60' : '80'  # For batch 1 (2nd batch), last node is 60; for batch 2 (3rd batch), last node is 80
              first_placeholder_number = batch_offset == 1 ? '3' : '4'  # For batch 1, next placeholder is 3; for batch 2, next placeholder is 4
              last_node_selector = "#archival_object_#{instance_variable_get("@ao#{last_node_number}_of_#{parent}").id}"
              expect(@parent_list).to have_css("#{last_node_selector} + [data-batch-placeholder='#{first_placeholder_number}']", visible: :all)
              if @batch_placeholders_arr.length > 1
                @batch_placeholders_arr.each_cons(2) do |prev, curr|
                  expect(@parent_list).to have_css("[data-batch-placeholder='#{prev}'] + [data-batch-placeholder='#{curr}']", visible: false)
                end
              end
            elsif batch_offset == @total_batches - 2
              # When second-to-last, we have batches n-2, n-1, and n loaded
              # Last placeholder should be for batch n-3, followed by first node of batch n-2
              last_placeholder = batch_offset - 2
              first_node_number_after_last_placeholder = (batch_offset - 1) * @tree_batch_size + 1
              node_selector = "#archival_object_#{instance_variable_get("@ao#{first_node_number_after_last_placeholder}_of_#{parent}").id}"
              expect(@parent_list).to have_css("[data-batch-placeholder='#{last_placeholder}'] + #{node_selector}", visible: :all)
              if @batch_placeholders_arr.length > 1
                @batch_placeholders_arr.each_cons(2) do |prev, curr|
                  expect(@parent_list).to have_css("[data-batch-placeholder='#{prev}'] + [data-batch-placeholder='#{curr}']", visible: false)
                end
              end
            else
              before_middle_placeholders = @batch_placeholders_arr.select { |p| p < batch_offset }
              after_middle_placeholders = @batch_placeholders_arr.select { |p| p > batch_offset }

              expect(@parent_list).to have_css("#archival_object_#{instance_variable_get("@ao20_of_#{parent}").id} + [data-batch-placeholder='#{before_middle_placeholders.first}']", visible: :all)
              if before_middle_placeholders.length > 1
                before_middle_placeholders.each_cons(2) do |prev, curr|
                  expect(@parent_list).to have_css("[data-batch-placeholder='#{prev}'] + [data-batch-placeholder='#{curr}']", visible: false)
                end
              end

              last_before_middle_placeholder_number = batch_offset - 2  # If batch_offset is 3, we want placeholder 1 (3-2)
              first_middle_node_number = (batch_offset - 1) * @tree_batch_size + 1  # If batch_offset is 3, we want first node of batch 2 (3-1)
              node_selector = "#archival_object_#{instance_variable_get("@ao#{first_middle_node_number}_of_#{parent}").id}"
              expect(@parent_list).to have_css("[data-batch-placeholder='#{last_before_middle_placeholder_number}'] + #{node_selector}", visible: :all)
              last_node_number = (batch_offset + 2) * @tree_batch_size  # If batch_offset is 3, we want last node of batch 4 (3+1), which is the 5th batch (3+2)
              first_placeholder_after = after_middle_placeholders.first
              last_node_selector = "#archival_object_#{instance_variable_get("@ao#{last_node_number}_of_#{parent}").id}"
              expect(@parent_list).to have_css("#{last_node_selector} + [data-batch-placeholder='#{first_placeholder_after}']", visible: :all)
              # Verify any remaining placeholders are in sequence
              if after_middle_placeholders.length > 1
                after_middle_placeholders.each_cons(2) do |prev, curr|
                  expect(@parent_list).to have_css("[data-batch-placeholder='#{prev}'] + [data-batch-placeholder='#{curr}']", visible: false)
                end
              end
            end
          end
        else
          expect(@parent_list).to_not have_css('[data-batch-placeholder]')
        end
      end

      # it 'fetches unpopulated batches on scroll' do
      # end
    end

    context 'when loading a page with a URI fragment' do
      describe 'should load the correct number of siblings' do
        it_behaves_like 'uri fragment batch rendering', 'ao7', 0
        it_behaves_like 'uri fragment batch rendering', 'ao7', 1
        it_behaves_like 'uri fragment batch rendering', 'ao7', 2
        it_behaves_like 'uri fragment batch rendering', 'ao7', 3
        it_behaves_like 'uri fragment batch rendering', 'ao7', 4
        it_behaves_like 'uri fragment batch rendering', 'ao7', 5

        it_behaves_like 'uri fragment batch rendering', 'ao3', 0
        it_behaves_like 'uri fragment batch rendering', 'ao3', 1
        it_behaves_like 'uri fragment batch rendering', 'ao3', 2
        it_behaves_like 'uri fragment batch rendering', 'ao3', 3
        it_behaves_like 'uri fragment batch rendering', 'ao3', 4

        it_behaves_like 'uri fragment batch rendering', 'ao4', 0
        it_behaves_like 'uri fragment batch rendering', 'ao4', 1
        it_behaves_like 'uri fragment batch rendering', 'ao4', 2

        it_behaves_like 'uri fragment batch rendering', 'ao5', 0
        it_behaves_like 'uri fragment batch rendering', 'ao5', 1

        it_behaves_like 'uri fragment batch rendering', 'ao6', 0
      end
    end
  end
end
