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

      # Create children for ao3 (81 children = 5 batches)
      81.times do |i|
        instance_variable_set("@ao#{i + 1}_of_ao3", create(:archival_object,
          resource: {'ref' => @resource.uri},
          parent: {'ref' => @ao3.uri},
          publish: true
        ))
      end

      # Create children for ao4 (41 children = 3 batches)
      41.times do |i|
        instance_variable_set("@ao#{i + 1}_of_ao4", create(:archival_object,
          resource: {'ref' => @resource.uri},
          parent: {'ref' => @ao4.uri},
          publish: true
        ))
      end

      # Create children for ao5 (21 children = 2 batches)
      21.times do |i|
        instance_variable_set("@ao#{i + 1}_of_ao5", create(:archival_object,
          resource: {'ref' => @resource.uri},
          parent: {'ref' => @ao5.uri},
          publish: true
        ))
      end

      # Create one child for ao6 1 batch
      @ao1_of_ao6 = create(:archival_object,
        resource: {'ref' => @resource.uri},
        parent: {'ref' => @ao6.uri},
        publish: true
      )

      run_indexers
    end

    shared_examples 'uri fragment batch rendering' do |parent, batch_position|
      before(:each) do
        total_nodes = case parent
                      when 'ao7' then 120
                      when 'ao3' then 81
                      when 'ao4' then 41
                      when 'ao5' then 21
                      when 'ao6' then 1
                      end
        @total_batches = (total_nodes / @tree_batch_size.to_f).ceil
        @batch_number = case batch_position
                        when :first then 0
                        when :last then @total_batches - 1
                        when Hash then batch_position[:middle]
                        end

        # For purposes of avoiding flaky tests from extra batches being loaded
        # via the InfiniteTree batchObserver after initial page load, we use
        # the middle node when a batch has more than one
        node_id = if @batch_number == @total_batches - 1 && (total_nodes % @tree_batch_size) == 1
                    total_nodes
                  else
                    (@batch_number * @tree_batch_size) + (@tree_batch_size / 2)
                  end
        node_var = "@ao#{node_id}_of_#{parent}"
        @expected_node_count = case batch_position
                               when :first then if @total_batches < 3
                                                  total_nodes
                                                else
                                                  @tree_batch_size * 2
                                                end
                               when :last then if @total_batches <= 3
                                                 total_nodes
                                               else
                                                 @tree_batch_size * 2 + (total_nodes % @tree_batch_size == 0 ? @tree_batch_size : total_nodes % @tree_batch_size)  # Show batches 0, N-2, N-1
                                               end
                               when Hash then
                                 if @total_batches < 4
                                   total_nodes
                                 else
                                   middle_batch = batch_position[:middle]
                                   if middle_batch == 1
                                     @tree_batch_size * 3
                                   elsif middle_batch == @total_batches - 2  # If we're in second-to-last batch
                                     @tree_batch_size * 3 + (total_nodes % @tree_batch_size == 0 ? @tree_batch_size : total_nodes % @tree_batch_size)  # Show batches 0, N-3, N-2, N-1
                                   else
                                     @tree_batch_size * 4  # Show batches 0, n-1, n, n+1
                                   end
                                 end
                               end
        @batch_placeholders_arr = case batch_position
                              when :first then (2..@total_batches - 1).to_a  # Start at 2 because batch 0 is always loaded
                              when :last then (1..@total_batches - 3).to_a   # End at n-3 because we load batches n-2, n-1
                              when Hash then
                                middle_batch = batch_position[:middle]
                                (1..middle_batch - 2).to_a + (middle_batch + 2..@total_batches - 1).to_a  # Skip batches before and after middle batch
                              end

        visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization#tree::archival_object_#{instance_variable_get(node_var).id}"
        wait_for_jquery
        node = find("#archival_object_#{instance_variable_get(node_var).id}.current")
        @parent_list = node.find(:xpath, '..')
      end

      it "loads the correct number of siblings" do
        begin
          expect(@parent_list).to have_css('.node', count: @expected_node_count)
        rescue RSpec::Expectations::ExpectationNotMetError => e
          puts "\nTest failed for parent: #{parent}, batch_position: #{batch_position.inspect}"
          puts "Expected #{@expected_node_count} nodes but found #{@parent_list.all('.node').count}"
          raise e
        end
      end

      it 'loads the correct batch placeholders' do
        if @batch_placeholders_arr.length > 0
          expect(@parent_list).to have_css('[data-batch-placeholder]', count: @batch_placeholders_arr.length, visible: false)

          case batch_position
          when :first # Batches loaded: 0, 1
            last_node_selector = "#archival_object_#{instance_variable_get("@ao40_of_#{parent}").id}"
            expect(@parent_list).to have_css("#archival_object_#{instance_variable_get("@ao40_of_#{parent}").id} + [data-batch-placeholder='2']", visible: false)
            if @batch_placeholders_arr.length > 1
              @batch_placeholders_arr.each_cons(2) do |prev, curr|
                expect(@parent_list).to have_css("[data-batch-placeholder='#{prev}'] + [data-batch-placeholder='#{curr}']", visible: false)
              end
            end
          when :last # Batches loaded: 0, n-2, n-1
            expect(@parent_list).to have_css("#archival_object_#{instance_variable_get("@ao20_of_#{parent}").id} + [data-batch-placeholder='1']", visible: false)
            expect(@parent_list).to have_css("[data-batch-placeholder='#{@batch_placeholders_arr.last}'] + #archival_object_#{instance_variable_get("@ao#{(@batch_number - 1) * @tree_batch_size + 1}_of_#{parent}").id}", visible: :all)
            if @batch_placeholders_arr.length > 1
              @batch_placeholders_arr.each_cons(2) do |prev, curr|
                expect(@parent_list).to have_css("[data-batch-placeholder='#{prev}'] + [data-batch-placeholder='#{curr}']", visible: false)
              end
            end
          when Hash # Batches loaded: 0, n-1, n, n+1
            middle_batch = batch_position[:middle]
            placeholders = @parent_list.all('[data-batch-placeholder]', visible: false)
            
            before_middle_batches = placeholders.select { |p| p[:'data-batch-placeholder'].to_i < middle_batch }
            after_middle_batches = placeholders.select { |p| p[:'data-batch-placeholder'].to_i > middle_batch }

            if middle_batch < 3
              last_node_number = middle_batch == 1 ? '60' : '80'  # For batch 1 (2nd batch), last node is 60; for batch 2 (3rd batch), last node is 80
              first_placeholder_number = middle_batch == 1 ? '3' : '4'  # For batch 1, next placeholder is 3; for batch 2, next placeholder is 4
              last_node_selector = "#archival_object_#{instance_variable_get("@ao#{last_node_number}_of_#{parent}").id}"
              expect(@parent_list).to have_css("#{last_node_selector} + [data-batch-placeholder='#{first_placeholder_number}']", visible: :all)
              if @batch_placeholders_arr.length > 1
                @batch_placeholders_arr.each_cons(2) do |prev, curr|
                  expect(@parent_list).to have_css("[data-batch-placeholder='#{prev}'] + [data-batch-placeholder='#{curr}']", visible: false)
                end
              end
            elsif middle_batch == @total_batches - 2
              # When middle_batch is second-to-last, we have batches n-2, n-1, and n loaded
              # Last placeholder should be for batch n-3, followed by first node of batch n-2
              last_placeholder = middle_batch - 2
              first_node_number_after_last_placeholder = (middle_batch - 1) * @tree_batch_size + 1
              node_selector = "#archival_object_#{instance_variable_get("@ao#{first_node_number_after_last_placeholder}_of_#{parent}").id}"
              expect(@parent_list).to have_css("[data-batch-placeholder='#{last_placeholder}'] + #{node_selector}", visible: :all)
              if @batch_placeholders_arr.length > 1
                @batch_placeholders_arr.each_cons(2) do |prev, curr|
                  expect(@parent_list).to have_css("[data-batch-placeholder='#{prev}'] + [data-batch-placeholder='#{curr}']", visible: false)
                end
              end
            else
              # For middle batches between 3 and second-to-last
              # split placeholders into before and after middle batch
              # for the before batch we need to find the first placeholder and verify that the last node of the first batch comes immediately before it
              # We also need to find the last placeholder before the middle batch
              # and the first node after that placeholder
              # for the after batch of placeholders we need to find the first placeholder and verify that the last of the middle nodes come immediately beforeit
              # then we need to verify that the remaining placeholders are in sequence
              before_middle_placeholders = @batch_placeholders_arr.select { |p| p < middle_batch }
              after_middle_placeholders = @batch_placeholders_arr.select { |p| p > middle_batch }

              expect(@parent_list).to have_css("#archival_object_#{instance_variable_get("@ao20_of_#{parent}").id} + [data-batch-placeholder='#{before_middle_placeholders.first}']", visible: :all)
              if before_middle_placeholders.length > 1
                before_middle_placeholders.each_cons(2) do |prev, curr|
                  expect(@parent_list).to have_css("[data-batch-placeholder='#{prev}'] + [data-batch-placeholder='#{curr}']", visible: false)
                end
              end

              last_before_middle_placeholder_number = middle_batch - 2  # If middle_batch is 3, we want placeholder 1 (3-2)
              first_middle_node_number = (middle_batch - 1) * @tree_batch_size + 1  # If middle_batch is 3, we want first node of batch 2 (3-1)
              node_selector = "#archival_object_#{instance_variable_get("@ao#{first_middle_node_number}_of_#{parent}").id}"
              expect(@parent_list).to have_css("[data-batch-placeholder='#{last_before_middle_placeholder_number}'] + #{node_selector}", visible: :all)
              last_node_number = (middle_batch + 2) * @tree_batch_size  # If middle_batch is 3, we want last node of batch 4 (3+1), which is the 5th batch (3+2)
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
        it_behaves_like 'uri fragment batch rendering', 'ao7', :first
        it_behaves_like 'uri fragment batch rendering', 'ao7', {:middle => 1}
        it_behaves_like 'uri fragment batch rendering', 'ao7', {:middle => 2}
        it_behaves_like 'uri fragment batch rendering', 'ao7', {:middle => 3}
        it_behaves_like 'uri fragment batch rendering', 'ao7', {:middle => 4}
        it_behaves_like 'uri fragment batch rendering', 'ao7', :last

        it_behaves_like 'uri fragment batch rendering', 'ao3', :first
        it_behaves_like 'uri fragment batch rendering', 'ao3', {:middle => 1}
        it_behaves_like 'uri fragment batch rendering', 'ao3', {:middle => 2}
        it_behaves_like 'uri fragment batch rendering', 'ao3', {:middle => 3}
        it_behaves_like 'uri fragment batch rendering', 'ao3', :last

        it_behaves_like 'uri fragment batch rendering', 'ao4', :first
        it_behaves_like 'uri fragment batch rendering', 'ao4', {:middle => 1}
        it_behaves_like 'uri fragment batch rendering', 'ao4', :last

        it_behaves_like 'uri fragment batch rendering', 'ao5', :first
        it_behaves_like 'uri fragment batch rendering', 'ao5', :last

        it_behaves_like 'uri fragment batch rendering', 'ao6', :first
      end
    end
  end
end
