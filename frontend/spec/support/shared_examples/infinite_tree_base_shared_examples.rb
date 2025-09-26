# Base shared examples for Infinite Tree feature specs
# These are generic building blocks consumed by the composed shared_examples
# in spec/support/shared_examples/infinite_tree_shared_examples.rb

RSpec.shared_examples 'basic node markup' do
  it_behaves_like 'node has role treeitem'
  it_behaves_like 'node has correct data-uri'
end

RSpec.shared_examples 'node has role treeitem' do
  it 'has role treeitem' do
    expect(node['role']).to eq('treeitem')
  end
end

RSpec.shared_examples 'node has correct data-uri' do
  it 'has the correct data-uri' do
    expect(node['data-uri']).to eq(expected_uri)
  end
end

RSpec.shared_examples 'node has no children' do
  it 'has no children' do
    aggregate_failures do
      expect(node).not_to have_css('[aria-expanded]')
      expect(node).not_to have_css('[data-has-expanded]')
      expect(node).not_to have_css(':scope > .node-row .node-expand')
      expect(node).not_to have_css(':scope > .node-children', visible: :all)
    end
  end
end

RSpec.shared_examples 'node has correct data-total-child-batches attribute' do
  it 'has the correct data-total-child-batches attribute' do
    if node[:class].include?('root')
      # root node only has the attribute on its .node-children list
      expect(node).to have_css(":scope > .node-children[data-total-child-batches='#{total_batches}']")
    else
      # nodes have the attribute on themselves and their .node-children list,
      # but .node-children isn't present if node hasn't been expanded yet,
      # so test the node for all cases
      expect(node['data-total-child-batches']).to eq(total_batches.to_s)
    end
  end
end

RSpec.shared_examples 'node has X children visible' do
  it 'is expanded with the correct number of children visible' do
    aggregate_failures do
      expect(node['aria-expanded']).to eq('true')
      expect(node['data-has-expanded']).to eq('true') unless node[:class].include?('root')
      expect(node).to have_css(':scope > .node-row .node-expand-icon.expanded') unless node[:class].include?('root')
      expect(node).to have_css(':scope > .node-children > .node', count: child_count, visible: true)
    end
  end
end

RSpec.shared_examples 'node has X children hidden' do
  it 'is collapsed with the correct number of hidden children' do
    aggregate_failures do
      expect(node['aria-expanded']).to eq('false')
      expect(node['data-has-expanded']).to eq('true')
      expect(node).to have_css(':scope > .node-row .node-expand-icon:not(.expanded)')
      expect(node).to have_css(':scope > .node-children > .node', count: child_count, visible: false)
    end
  end
end

RSpec.shared_examples 'parent node has not been expanded' do
  it 'has not been expanded' do
    aggregate_failures do
      expect(node['aria-expanded']).to eq('false')
      expect(node['data-has-expanded']).to eq('false')
      expect(node).to have_css(':scope > .node-row .node-expand-icon:not(.expanded)')
      expect(node).not_to have_css(':scope > .node-children', visible: :all)
    end
  end
end

RSpec.shared_examples 'parent node expands on expand button click' do
  before do
    node.find(':scope > .node-row .node-expand').click
    wait_for_ajax
  end

  it_behaves_like 'node has X children visible'
end

RSpec.shared_examples 'parent node expands on title click' do
  before do
    node.find(':scope > .node-row .record-title').click
    wait_for_ajax
  end

  it_behaves_like 'node has X children visible'
end

RSpec.shared_examples 'parent node expands on keydown' do
  it_behaves_like 'parent node expands on space keydown on expand button'
  it_behaves_like 'parent node expands on enter keydown on expand button'
end

RSpec.shared_examples 'parent node expands on space keydown on expand button' do
  before do
    node.find(':scope > .node-row .node-expand').send_keys(:space)
    wait_for_ajax
  end

  it_behaves_like 'node has X children visible'
end

RSpec.shared_examples 'parent node expands on enter keydown on expand button' do
  before do
    node.find(':scope > .node-row .node-expand').send_keys(:enter)
    wait_for_ajax
  end

  it_behaves_like 'node has X children visible'
end

RSpec.shared_examples 'parent node collapses on expand button click' do
  before do
    node.find(':scope > .node-row .node-expand').click
    wait_for_ajax
    node.find(':scope > .node-row .node-expand').click
  end

  it_behaves_like 'node has X children hidden'
end

RSpec.shared_examples 'parent node collapses on keydown' do
  it_behaves_like 'parent node collapses on space keydown on expand button'
  it_behaves_like 'parent node collapses on enter keydown on expand button'
end

RSpec.shared_examples 'parent node collapses on space keydown on expand button' do
  before do
    node.find(':scope > .node-row .node-expand').send_keys(:space)
    wait_for_ajax
    node.find(':scope > .node-row .node-expand').send_keys(:space)
  end

  it_behaves_like 'node has X children hidden'
end

RSpec.shared_examples 'parent node collapses on enter keydown on expand button' do
  before do
    node.find(':scope > .node-row .node-expand').send_keys(:enter)
    wait_for_ajax
    node.find(':scope > .node-row .node-expand').send_keys(:enter)
  end

  it_behaves_like 'node has X children hidden'
end

RSpec.shared_examples 'child list has an observer node for the second batch' do
  it 'has an observer node for the second batch' do
    expect(child_list).to have_css('[data-observe-node][data-observe-offset="1"]')
  end
end

RSpec.shared_examples 'child list has the correct number of batch placeholders' do
  it 'has the correct number of batch placeholders' do
    expect(child_list).to have_css(':scope > li[data-batch-placeholder]', count: batches_not_yet_loaded.size, visible: false)

    batches_not_yet_loaded.each do |batch_number|
      expect(child_list).to have_css(":scope > li[data-batch-placeholder='#{batch_number}']", visible: false)
    end
  end
end

RSpec.shared_examples 'child list lazy loads the remaining batches of children on scroll' do
  it 'loads batches of children on scroll' do
    batches_not_yet_loaded.each do |batch_number|
      present_children_count = child_list.all(':scope > li.node', visible: true).size
      expect(present_children_count).to be < total_child_count

      observer_node = child_list.find("[data-observe-offset='#{batch_number}']", match: :first)
      container.scroll_to(observer_node, align: :center)
      wait_for_ajax
    end

    aggregate_failures do
      expect(child_list).to have_css(':scope > li', count: total_child_count, visible: :all)
      expect(child_list).to have_css(':scope > li.node', count: total_child_count, visible: true)
      expect(child_list).not_to have_css(':scope > li[data-batch-placeholder]', visible: :all)
    end
  end
end

RSpec.shared_examples 'collapsing hides all previously loaded children' do
  it 'collapses and hides all previously loaded children' do
    batches_to_load.each_with_index do |batch_number, i|
      if node['aria-expanded'] == 'false'
        node.find(':scope > .node-row .node-expand').click
        wait_for_ajax
      end

      observer_node = child_list.find("[data-observe-offset='#{batch_number}']", match: :first)
      container.scroll_to(observer_node, align: :center)
      wait_for_ajax

      node.find(':scope > .node-row .node-expand').click
      wait_for_ajax

      expected_child_count = [child_count_on_initial_expand + (i + 1) * Rails.configuration.infinite_tree_batch_size, total_child_count].min
      expect(child_list).to have_css(':scope > li.node', count: expected_child_count, visible: false)
    end
  end
end

RSpec.shared_examples 'expanding shows all previously loaded children' do
  it 'expands and shows all previously loaded children' do
    batches_to_load.each_with_index do |batch_number, i|
      if node['aria-expanded'] == 'false'
        node.find(':scope > .node-row .node-expand').click
        wait_for_ajax
      end

      observer_node = child_list.find("[data-observe-offset='#{batch_number}']", match: :first)
      container.scroll_to(observer_node, align: :center)
      wait_for_ajax

      node.find(':scope > .node-row .node-expand').click
      wait_for_ajax

      node.find(':scope > .node-row .node-expand').click
      wait_for_ajax

      expected_child_count = [child_count_on_initial_expand + (i + 1) * Rails.configuration.infinite_tree_batch_size, total_child_count].min
      expect(child_list).to have_css(':scope > li.node', count: expected_child_count, visible: true)
    end
  end
end
