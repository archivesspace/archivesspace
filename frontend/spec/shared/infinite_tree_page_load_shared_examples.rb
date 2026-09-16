# frozen_string_literal: true

RSpec.shared_examples 'having basic details of uri fragment batch rendering' do
  it 'shows the node of interest' do
    node_row = node.find(':scope > .node-row')
    aggregate_failures do
      expect(node_row).to appear_in_tree_viewport
      expect(page).to have_css(
        '#infinite-tree-container .node.current',
        count: 1,
        visible: :all
      )
    end
  end

  it 'loads the correct number of sibling nodes' do
    expect(parent_list).to have_css('.node', count: expected_node_count_on_page_load)
  end
end

RSpec.shared_examples 'loading the first batch' do
  it 'contains the first batch' do
    aggregate_failures 'includes the first node of the batch' do
      curr_node_id = instance_variable_get("@#{child_prefix}1_of_#{parent}").id
      expect(parent_list).to have_css(":scope > ##{child_type}_#{curr_node_id}:first-child")
    end

    aggregate_failures 'includes the middle nodes of the batch' do
      (2..@tree_batch_size - 1).each do |node_num|
        curr_node_id = instance_variable_get("@#{child_prefix}#{node_num}_of_#{parent}").id
        next_node_id = instance_variable_get("@#{child_prefix}#{node_num + 1}_of_#{parent}").id
        expect(parent_list).to have_css("##{child_type}_#{curr_node_id} + ##{child_type}_#{next_node_id}")
      end
    end

    aggregate_failures 'includes the last node of the batch' do
      curr_node_id = instance_variable_get("@#{child_prefix}#{@tree_batch_size}_of_#{parent}").id
      prev_node_id = instance_variable_get("@#{child_prefix}#{@tree_batch_size - 1}_of_#{parent}").id
      expect(parent_list).to have_css("##{child_type}_#{prev_node_id} + ##{child_type}_#{curr_node_id}")
    end
  end
end

RSpec.shared_examples 'loading middle batches' do
  it 'loads middle batches of nodes in the correct order' do
    expected_populated_batches.each do |batch_offset|
      next if batch_offset == 0 # skip first batch, already tested
      next if batch_offset == total_batches - 1 # skip last batch, already tested

      prev_batch_was_populated = expected_populated_batches.include?(batch_offset - 1)
      curr_batch_first_node_id = instance_variable_get("@#{child_prefix}#{batch_offset * @tree_batch_size + 1}_of_#{parent}").id

      if prev_batch_was_populated
        aggregate_failures 'loads the first node of the current batch after the last node of the previous batch' do
          prev_batch_last_node_id = instance_variable_get("@#{child_prefix}#{batch_offset * @tree_batch_size}_of_#{parent}").id
          expect(parent_list).to have_css("##{child_type}_#{prev_batch_last_node_id} + ##{child_type}_#{curr_batch_first_node_id}")
        end
      else
        aggregate_failures 'loads the first node of the current batch after the previous batch placeholder' do
          expect(parent_list).to have_css("[data-batch-placeholder='#{batch_offset - 1}'] + ##{child_type}_#{curr_batch_first_node_id}", visible: :all)
        end
      end

      (batch_offset * @tree_batch_size + 1..(batch_offset + 1) * @tree_batch_size).each do |node_num|
        curr_node_id = instance_variable_get("@#{child_prefix}#{node_num}_of_#{parent}").id

        if node_num < (batch_offset + 1) * @tree_batch_size
          aggregate_failures 'loads the first through the second-to-last node of the current batch in order' do
            next_node_id = instance_variable_get("@#{child_prefix}#{node_num + 1}_of_#{parent}").id
            expect(parent_list).to have_css("##{child_type}_#{curr_node_id} + ##{child_type}_#{next_node_id}")
          end
        else
          aggregate_failures 'loads the last node of the current batch in order' do
            prev_node_id = instance_variable_get("@#{child_prefix}#{node_num - 1}_of_#{parent}").id
            expect(parent_list).to have_css("##{child_type}_#{prev_node_id} + ##{child_type}_#{curr_node_id}")
          end
        end

      end
    end
  end
end

RSpec.shared_examples 'loading the last batch' do
  it 'loads the last batch' do
    batch_offset = total_batches - 1
    second_to_last_batch_last_node_id = instance_variable_get("@#{child_prefix}#{batch_offset * @tree_batch_size}_of_#{parent}").id
    last_batch_first_node_position = batch_offset * @tree_batch_size + 1
    last_batch_first_node_id = instance_variable_get("@#{child_prefix}#{last_batch_first_node_position}_of_#{parent}").id

    aggregate_failures 'loads the first node of the last batch' do
      expect(parent_list).to have_css("##{child_type}_#{second_to_last_batch_last_node_id} + ##{child_type}_#{last_batch_first_node_id}")
    end

    if last_batch_first_node_position < total_nodes # not last node in this batch
      (last_batch_first_node_position..total_nodes).each do |node_num|
        curr_node_id = instance_variable_get("@#{child_prefix}#{node_num}_of_#{parent}").id

        if node_num < total_nodes
          aggregate_failures 'loads the middle nodes of the last batch in the correct order' do
            next_node_id = instance_variable_get("@#{child_prefix}#{node_num + 1}_of_#{parent}").id
            expect(parent_list).to have_css("##{child_type}_#{curr_node_id} + ##{child_type}_#{next_node_id}")
          end
        else
          aggregate_failures 'loads the last node of the last batch' do
            prev_node_id = instance_variable_get("@#{child_prefix}#{node_num - 1}_of_#{parent}").id
            expect(parent_list).to have_css("##{child_type}_#{prev_node_id} + ##{child_type}_#{curr_node_id}")
            expect(parent_list).to have_css(":scope > ##{child_type}_#{curr_node_id}:last-child")
          end
        end

      end
    end
  end
end

RSpec.shared_examples 'including placeholders for non-loaded batches' do
  it 'includes placeholders for batches that are not populated' do
    expected_batch_placeholders.each do |batch_offset|
      prev_batch_was_populated = expected_populated_batches.include?(batch_offset - 1)

      if prev_batch_was_populated
        aggregate_failures 'includes a placeholder after the last node of the previous batch' do
          prev_batch_last_node_id = instance_variable_get("@#{child_prefix}#{batch_offset * @tree_batch_size}_of_#{parent}").id
          expect(parent_list).to have_css("##{child_type}_#{prev_batch_last_node_id} + [data-batch-placeholder='#{batch_offset}']", visible: :all)
        end
      else
        aggregate_failures 'includes a placeholder after the previous placeholder' do
          expect(parent_list).to have_css("[data-batch-placeholder='#{batch_offset - 1}'] + [data-batch-placeholder='#{batch_offset}']", visible: false)
        end
      end
    end
  end
end

RSpec.shared_examples 'including the last batch placeholder' do
  it 'includes the last batch placeholder' do
    expect(parent_list).to have_css(":scope > [data-batch-placeholder='#{total_batches - 1}']:last-child", visible: :all)
  end
end

RSpec.shared_examples 'scrolling loads remaining batches' do
  it 'fetches remaining batches of siblings on scroll' do
    container = page.find('#infinite-tree-container')

    expected_batch_placeholders.each do |batch_offset|
      wait_for_ajax
      observer_node = parent_list.first("[data-observe-offset='#{batch_offset}']")
      container.scroll_to(observer_node, align: :center)
    end

    wait_for_ajax
    expect(parent_list).to have_css('.node', count: total_nodes)
    expect(parent_list).not_to have_css('[data-batch-placeholder]', visible: false)
  end
end

RSpec.shared_examples 'having all nodes loaded' do
  it 'has all sibling nodes loaded' do
    expect(parent_list).to have_css('.node', count: total_nodes)
    expect(parent_list).not_to have_css('[data-batch-placeholder]', visible: false)
  end
end

RSpec.shared_examples 'normalizing invalid location hashes on the show view' do
  context 'when the location hash is invalid' do
    context 'with a malformed hash' do
      it 'rewrites the hash to root, rendering the tree root as the current node' do
        visit "#{show_path}#invalid_hash"
        wait_for_ajax

        aggregate_failures do
          expect(page.current_url).to match(
            %r{#{Regexp.escape(show_path)}#tree::#{root_type}_#{root_id}}
          )
          expect(page).to have_css('#infinite-tree-container .infinite-tree .root.current')
          expect(page).to have_css(
            '#infinite-tree-container .node.current',
            count: 1,
            visible: :all
          )
        end
      end
    end

    context 'with valid shape but non-existent record id' do
      it 'renders the tree for the root and shows error in the record pane' do
        visit "#{show_path}#tree::#{child_type}_999999"

        aggregate_failures do
          expect(page).to have_css('#infinite-tree-container .infinite-tree .root')
          expect(page).not_to have_css(
            '#infinite-tree-container .current',
            visible: :all
          )
          expect(page).to have_css(
            '#infinite-tree-record-pane .alert.alert-danger',
            text: 'Record Not Found'
          )
        end
      end
    end
  end
end
