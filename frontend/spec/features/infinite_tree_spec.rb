require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree', js: true do
  BATCH_SIZE = Rails.configuration.infinite_tree_batch_size
  let(:now) { Time.now.to_i }
  let(:repo) { create(:repo, repo_code: "infinite_tree_test_#{now}") }

  shared_examples 'basic node markup' do
    it_behaves_like 'node has role treeitem'
    it_behaves_like 'node has correct data-uri'
  end

  shared_examples 'node has role treeitem' do
    it 'has role treeitem' do
      expect(node['role']).to eq('treeitem')
    end
  end

  shared_examples 'node has correct data-uri' do
    it 'has the correct data-uri' do
      expect(node['data-uri']).to eq(expected_uri)
    end
  end

  shared_examples 'node has no children' do
    it 'has no children' do
      aggregate_failures do
        expect(node).not_to have_css('[aria-expanded]')
        expect(node).not_to have_css('[data-has-expanded]')
        expect(node).not_to have_css(':scope > .node-row .node-expand')
        expect(node).not_to have_css(':scope > .node-children', visible: :all)
      end
    end
  end

  shared_examples 'node has correct data-total-child-batches attribute' do
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

  shared_examples 'node has X children visible' do
    it 'is expanded with the correct number of children visible' do
      aggregate_failures do
        expect(node['aria-expanded']).to eq('true')
        expect(node['data-has-expanded']).to eq('true') unless node[:class].include?('root')
        expect(node).to have_css(':scope > .node-row .node-expand-icon.expanded') unless node[:class].include?('root')
        expect(node).to have_css(':scope > .node-children > .node', count: child_count, visible: true)
      end
    end
  end

  shared_examples 'node has X children hidden' do
    it 'is collapsed with the correct number of hidden children' do
      aggregate_failures do
        expect(node['aria-expanded']).to eq('false')
        expect(node['data-has-expanded']).to eq('true')
        expect(node).to have_css(':scope > .node-row .node-expand-icon:not(.expanded)')
        expect(node).to have_css(':scope > .node-children > .node', count: child_count, visible: false)
      end
    end
  end

  shared_examples 'parent node has not been expanded' do
    it 'has not been expanded' do
      aggregate_failures do
        expect(node['aria-expanded']).to eq('false')
        expect(node['data-has-expanded']).to eq('false')
        expect(node).to have_css(':scope > .node-row .node-expand-icon:not(.expanded)')
        expect(node).not_to have_css(':scope > .node-children', visible: :all)
      end
    end
  end

  shared_examples 'parent node expands on expand button click' do
    before do
      node.find(':scope > .node-row .node-expand').click
      wait_for_ajax
    end

    it_behaves_like 'node has X children visible'
  end

  shared_examples 'parent node expands on title click' do
    before do
      node.find(':scope > .node-row .record-title').click
      wait_for_ajax
    end

    it_behaves_like 'node has X children visible'
  end

  shared_examples 'parent node expands on keydown' do
    it_behaves_like 'parent node expands on space keydown on expand button'
    it_behaves_like 'parent node expands on enter keydown on expand button'
  end

  shared_examples 'parent node expands on space keydown on expand button' do
    before do
      node.find(':scope > .node-row .node-expand').send_keys(:space)
      wait_for_ajax
    end

    it_behaves_like 'node has X children visible'
  end

  shared_examples 'parent node expands on enter keydown on expand button' do
    before do
      node.find(':scope > .node-row .node-expand').send_keys(:enter)
      wait_for_ajax
    end

    it_behaves_like 'node has X children visible'
  end

  shared_examples 'parent node collapses on expand button click' do
    before do
      node.find(':scope > .node-row .node-expand').click
      wait_for_ajax
      node.find(':scope > .node-row .node-expand').click
    end

    it_behaves_like 'node has X children hidden'
  end

  shared_examples 'parent node collapses on keydown' do
    it_behaves_like 'parent node collapses on space keydown on expand button'
    it_behaves_like 'parent node collapses on enter keydown on expand button'
  end

  shared_examples 'parent node collapses on space keydown on expand button' do
    before do
      node.find(':scope > .node-row .node-expand').send_keys(:space)
      wait_for_ajax
      node.find(':scope > .node-row .node-expand').send_keys(:space)
    end

    it_behaves_like 'node has X children hidden'
  end

  shared_examples 'parent node collapses on enter keydown on expand button' do
    before do
      node.find(':scope > .node-row .node-expand').send_keys(:enter)
      wait_for_ajax
      node.find(':scope > .node-row .node-expand').send_keys(:enter)
    end

    it_behaves_like 'node has X children hidden'
  end

  shared_examples 'child list has an observer node for the second batch' do
    it 'has an observer node for the second batch' do
      expect(child_list).to have_css('[data-observe-node][data-observe-offset="1"]')
    end
  end

  shared_examples 'child list has the correct number of batch placeholders' do
    it 'has the correct number of batch placeholders' do
      expect(child_list).to have_css(':scope > li[data-batch-placeholder]', count: batches_not_yet_loaded.size, visible: false)

      batches_not_yet_loaded.each do |batch_number|
        expect(child_list).to have_css(":scope > li[data-batch-placeholder='#{batch_number}']", visible: false)
      end
    end
  end

  shared_examples 'child list lazy loads the remaining batches of children on scroll' do
    it 'loads batches of children on scroll' do
      batches_not_yet_loaded.each do |batch_number|
        present_children_count = child_list.all(':scope > li.node', visible: true).size
        expect(present_children_count).to be < total_child_count

        observer_node = child_list.find("[data-observe-offset='#{batch_number}']", match: :first) # sometimes there are two nodes observing for the same batch
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

  shared_examples 'collapsing hides all previously loaded children' do
    # This could be refactored to report one example per batch instead of one example for all batches combined
    it 'collapses and hides all previously loaded children' do
      batches_to_load.each_with_index do |batch_number, i|
        if node['aria-expanded'] == 'false'
          node.find(':scope > .node-row .node-expand').click
          wait_for_ajax
        end

        observer_node = child_list.find("[data-observe-offset='#{batch_number}']", match: :first) # sometimes there are two nodes observing for the same batch
        container.scroll_to(observer_node, align: :center)
        wait_for_ajax

        node.find(':scope > .node-row .node-expand').click
        wait_for_ajax

        expected_child_count = [child_count_on_initial_expand + (i + 1) * BATCH_SIZE, total_child_count].min
        expect(child_list).to have_css(':scope > li.node', count: expected_child_count, visible: false)
      end
    end
  end

  shared_examples 'expanding shows all previously loaded children' do
    # This could be refactored to report one example per batch instead of one example for all batches combined
    it 'expands and shows all previously loaded children' do
      batches_to_load.each_with_index do |batch_number, i|
        if node['aria-expanded'] == 'false'
          node.find(':scope > .node-row .node-expand').click
          wait_for_ajax
        end

        observer_node = child_list.find("[data-observe-offset='#{batch_number}']", match: :first) # sometimes there are two nodes observing for the same batch
        container.scroll_to(observer_node, align: :center)
        wait_for_ajax

        node.find(':scope > .node-row .node-expand').click
        wait_for_ajax

        node.find(':scope > .node-row .node-expand').click
        wait_for_ajax

        expected_child_count = [child_count_on_initial_expand + (i + 1) * BATCH_SIZE, total_child_count].min
        expect(child_list).to have_css(':scope > li.node', count: expected_child_count, visible: true)
      end
    end
  end

  context 'on the resources show view' do
    shared_examples 'renders base columns' do
      it 'renders the base columns' do
        aggregate_failures do
          expect(tree).to have_css('[data-column="title"]', visible: true)
          expect(tree).to have_css('[data-column="level"]', visible: :all)
          expect(tree).to have_css('[data-column="type"]', visible: :all)
          expect(tree).to have_css('[data-column="container"]', visible: :all)
        end
      end
    end

    shared_examples 'identifier column visible' do
      it 'shows the identifier column' do
        expect(tree).to have_css('[data-column="identifier"]', visible: :all)
      end
    end

    shared_examples 'identifier column hidden' do
      it 'does not show the identifier column' do
        expect(tree).not_to have_css('[data-column="identifier"]', visible: :all)
      end
    end

    let(:resource) { create(:resource, title: "Resource #{now}") }
    let(:ao) { create(:archival_object, resource: { 'ref' => resource.uri }, title: "Archival Object #{now}") }

    # Shared contexts for incremental record creation
    # 1 child → 10 children → BATCH_SIZE+1 → 2*BATCH_SIZE+1 → 3*BATCH_SIZE+1

    shared_context 'with 1 archival object child' do
      let!(:ao_1) do
        create(
          :archival_object,
          resource: { 'ref' => resource.uri },
          title: "AO 1 #{now}"
        )
      end
      let(:all_aos) { [ao_1] }
    end

    shared_context 'with 10 archival object children' do
      include_context 'with 1 archival object child'
      let!(:aos_2_to_10) do
        (2..10).map do |i|
          create(
            :archival_object,
            resource: { 'ref' => resource.uri },
            title: "AO #{i} #{now}"
          )
        end
      end
      let(:all_aos) { [ao_1] + aos_2_to_10 }
    end

    shared_context 'with BATCH_SIZE+1 archival objects' do
      include_context 'with 10 archival object children'
      let(:first_batch_count) { BATCH_SIZE + 1 }
      let!(:aos_11_to_first_batch) do
        additional_needed = first_batch_count - 10
        (11..(10 + additional_needed)).map do |i|
          create(
            :archival_object,
            resource: { 'ref' => resource.uri },
            title: "AO #{i} #{now}"
          )
        end
      end
      let(:all_aos) { [ao_1] + aos_2_to_10 + aos_11_to_first_batch }
    end

    shared_context 'with 2*BATCH_SIZE+1 archival objects' do
      include_context 'with BATCH_SIZE+1 archival objects'
      let(:second_batch_count) { BATCH_SIZE * 2 + 1 }
      let!(:aos_to_second_batch) do
        previous_count = first_batch_count
        additional_needed = second_batch_count - previous_count
        ((previous_count + 1)..(previous_count + additional_needed)).map do |i|
          create(
            :archival_object,
            resource: { 'ref' => resource.uri },
            title: "AO #{i} #{now}"
          )
        end
      end
      let(:all_aos) { [ao_1] + aos_2_to_10 + aos_11_to_first_batch + aos_to_second_batch }
    end

    shared_context 'with 3*BATCH_SIZE+1 archival objects' do
      include_context 'with 2*BATCH_SIZE+1 archival objects'
      let(:third_batch_count) { BATCH_SIZE * 3 + 1 }
      let!(:aos_to_third_batch) do
        previous_count = second_batch_count
        additional_needed = third_batch_count - previous_count
        ((previous_count + 1)..(previous_count + additional_needed)).map do |i|
          create(
            :archival_object,
            resource: { 'ref' => resource.uri },
            title: "AO #{i} #{now}"
          )
        end
      end
      let(:all_aos) { [ao_1] + aos_2_to_10 + aos_11_to_first_batch + aos_to_second_batch + aos_to_third_batch }
    end

    # Shared contexts for parent node tests that leverage the archival objects from above
    shared_context 'parent node with 1 child' do
      include_context 'with 1 archival object child'
      let(:parent_ao) { ao_1 }
      let!(:parent_child) do
        create(
          :archival_object,
          resource: { 'ref' => resource.uri },
          parent: { 'ref' => parent_ao.uri },
          title: "Child of AO #{now}"
        )
      end
    end

    shared_context 'parent node with 10 children' do
      include_context 'with 10 archival object children'
      let(:parent_ao) { aos_2_to_10.first }  # Use second AO as parent
      let!(:parent_children) do
        10.times.map do |i|
          create(
            :archival_object,
            resource: { 'ref' => resource.uri },
            parent: { 'ref' => parent_ao.uri },
            title: "Child #{i + 1} of AO #{now}"
          )
        end
      end
    end

    shared_context 'parent node with BATCH_SIZE+1 children' do
      include_context 'with BATCH_SIZE+1 archival objects'
      let(:parent_ao) { aos_11_to_first_batch.first }  # Use one of the later AOs as parent
      let(:parent_child_count) { BATCH_SIZE + 1 }
      let!(:parent_children) do
        parent_child_count.times.map do |i|
          create(
            :archival_object,
            resource: { 'ref' => resource.uri },
            parent: { 'ref' => parent_ao.uri },
            title: "Child #{i + 1} of AO #{now}"
          )
        end
      end
    end

    shared_context 'parent node with 2*BATCH_SIZE+1 children' do
      include_context 'with 2*BATCH_SIZE+1 archival objects'
      # Use one of the early AOs that are direct children of the resource, not deep nested ones
      let(:parent_ao) { aos_2_to_10[1] }  # Use the 3rd AO (AO 3) as parent - it's a direct child of resource
      let(:parent_child_count) { BATCH_SIZE * 2 + 1 }
      let!(:parent_children) do
        parent_child_count.times.map do |i|
          create(
            :archival_object,
            resource: { 'ref' => resource.uri },
            parent: { 'ref' => parent_ao.uri },
            title: "Child #{i + 1} of AO #{now}"
          )
        end
      end
    end

    shared_context 'parent node with 3*BATCH_SIZE+1 children' do
      include_context 'with 3*BATCH_SIZE+1 archival objects'
      # Use one of the early AOs that are direct children of the resource, not deep nested ones
      let(:parent_ao) { aos_2_to_10[2] }  # Use the 4th AO (AO 4) as parent - it's a direct child of resource
      let(:parent_child_count) { BATCH_SIZE * 3 + 1 }
      let!(:parent_children) do
        parent_child_count.times.map do |i|
          create(
            :archival_object,
            resource: { 'ref' => resource.uri },
            parent: { 'ref' => parent_ao.uri },
            title: "Child #{i + 1} of AO #{now}"
          )
        end
      end
    end

    before(:each) do
      set_repo(repo)
      login_admin
      select_repository(repo)
      ao
    end

    subject(:tree) do
      visit "/resources/#{resource.id}"
      wait_for_ajax
      find('.infinite-tree')
    end

    let(:container) { find('#infinite-tree-container') }

    describe 'tree list' do
      it 'has role tree' do
        expect(tree['role']).to eq('tree')
      end

      it 'has one child' do
        expect(tree).to have_css(':scope > li', count: 1)
        expect(tree).to have_css(':scope > li.root.node')
      end
    end

    context 'root node' do
      describe 'with no children' do
        let(:ao) { nil }
        let(:resource) { create(:resource, title: "Resource #{now}") }
        let(:node) { tree.find("#resource_#{resource.id}") }
        let(:expected_uri) { resource.uri }

        include_examples 'basic node markup'
        it_behaves_like 'node has no children'
      end

      describe 'with one child' do
        include_context 'with 1 archival object child'
        let(:ao) { nil }  # Override the context-level ao to prevent extra child
        let(:node) { tree.find("#resource_#{resource.id}") }
        let(:expected_uri) { resource.uri }
        let(:total_batches) { 1 }
        let(:child_count) { 1 }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'node has X children visible'
      end

      describe 'with ten children' do
        include_context 'with 10 archival object children'
        let(:ao) { nil }  # Override the context-level ao to prevent extra child
        let(:node) { tree.find("#resource_#{resource.id}") }
        let(:expected_uri) { resource.uri }
        let(:total_batches) { 1 }
        let(:child_count) { 10 }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'node has X children visible'
      end

      describe 'with two batches of children' do
        include_context 'with BATCH_SIZE+1 archival objects'
        let(:ao) { nil }  # Override the context-level ao to prevent extra child
        let(:total_child_count) { BATCH_SIZE + 1 }
        child_count_before_lazy_loading_batches = BATCH_SIZE
        let(:node) { tree.find("#resource_#{resource.id}") }
        let(:expected_uri) { resource.uri }
        let(:child_list) { node.find(':scope > .node-children') }
        let(:total_batches) { 2 }
        let(:child_count) { child_count_before_lazy_loading_batches }
        let(:batches_not_yet_loaded) { [1] }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'node has X children visible'
        it_behaves_like 'child list has an observer node for the second batch'
        it_behaves_like 'child list has the correct number of batch placeholders'
        it_behaves_like 'child list lazy loads the remaining batches of children on scroll'
      end

      describe 'with three batches of children' do
        include_context 'with 2*BATCH_SIZE+1 archival objects'
        let(:ao) { nil }  # Override the context-level ao to prevent extra child
        let(:total_child_count) { BATCH_SIZE * 2 + 1 }
        child_count_before_lazy_loading_batches = BATCH_SIZE
        let(:node) { tree.find("#resource_#{resource.id}") }
        let(:expected_uri) { resource.uri }
        let(:child_list) { node.find(':scope > .node-children') }
        let(:total_batches) { 3 }
        let(:child_count) { child_count_before_lazy_loading_batches }
        let(:batches_not_yet_loaded) { [1, 2] }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'node has X children visible'
        it_behaves_like 'child list has an observer node for the second batch'
        it_behaves_like 'child list has the correct number of batch placeholders'
        it_behaves_like 'child list lazy loads the remaining batches of children on scroll'
      end

      describe 'with four batches of children' do
        include_context 'with 3*BATCH_SIZE+1 archival objects'
        let(:ao) { nil }  # Override the context-level ao to prevent extra child
        let(:total_child_count) { BATCH_SIZE * 3 + 1 }
        child_count_before_lazy_loading_batches = BATCH_SIZE
        let(:node) { tree.find("#resource_#{resource.id}") }
        let(:expected_uri) { resource.uri }
        let(:child_list) { node.find(':scope > .node-children') }
        let(:total_batches) { 4 }
        let(:child_count) { child_count_before_lazy_loading_batches }
        let(:batches_not_yet_loaded) { [1, 2, 3] }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'node has X children visible'
        it_behaves_like 'child list has an observer node for the second batch'
        it_behaves_like 'child list has the correct number of batch placeholders'
        it_behaves_like 'child list lazy loads the remaining batches of children on scroll'
      end
    end

    context 'parent node' do
      describe 'with one child' do
        include_context 'parent node with 1 child'
        let(:node) { tree.find("#archival_object_#{parent_ao.id}") }
        let(:expected_uri) { parent_ao.uri }
        let(:total_batches) { 1 }
        let(:child_count) { 1 }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'parent node has not been expanded'

        describe 'expands' do
          it_behaves_like 'parent node expands on expand button click'
          it_behaves_like 'parent node expands on title click'
          it_behaves_like 'parent node expands on keydown'
        end

        describe 'collapses' do
          it_behaves_like 'parent node collapses on expand button click'
          it_behaves_like 'parent node collapses on keydown'
        end
      end

      describe 'with ten children' do
        include_context 'parent node with 10 children'
        let(:node) { tree.find("#archival_object_#{parent_ao.id}") }
        let(:expected_uri) { parent_ao.uri }
        let(:total_batches) { 1 }
        let(:child_count) { 10 }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'parent node has not been expanded'

        describe 'expands' do
          it_behaves_like 'parent node expands on expand button click'
          it_behaves_like 'parent node expands on title click'
          it_behaves_like 'parent node expands on keydown'
        end

        describe 'collapses' do
          it_behaves_like 'parent node collapses on expand button click'
          it_behaves_like 'parent node collapses on keydown'
        end
      end

      describe 'with two batches of children' do
        include_context 'parent node with BATCH_SIZE+1 children'
        let(:total_child_count) { BATCH_SIZE + 1 }
        child_count_on_expand_before_lazy_loading_batches = BATCH_SIZE
        let(:node) { tree.find("#archival_object_#{parent_ao.id}") }
        let(:expected_uri) { parent_ao.uri }
        let(:total_batches) { 2 }
        let(:child_count) { child_count_on_expand_before_lazy_loading_batches }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'parent node has not been expanded'

        describe 'expands' do
          it_behaves_like 'parent node expands on expand button click'
          it_behaves_like 'parent node expands on title click'
          it_behaves_like 'parent node expands on keydown'
        end

        describe 'collapses' do
          it_behaves_like 'parent node collapses on expand button click'
          it_behaves_like 'parent node collapses on keydown'
        end

        describe 'after initial expansion' do
          before do
            node.find(':scope > .node-row .node-expand').click
            wait_for_ajax
          end

          let(:child_list) { node.find(':scope > .node-children') }
          let(:batches_not_yet_loaded) { [1] }

          it_behaves_like 'child list has an observer node for the second batch'
          it_behaves_like 'child list has the correct number of batch placeholders'
          it_behaves_like 'child list lazy loads the remaining batches of children on scroll'
        end
      end

      describe 'with three batches of children' do
        include_context 'parent node with 2*BATCH_SIZE+1 children'
        let(:total_child_count) { BATCH_SIZE * 2 + 1 }
        child_count_on_expand_before_lazy_loading_batches = BATCH_SIZE
        let(:node) { tree.find("#archival_object_#{parent_ao.id}") }
        let(:expected_uri) { parent_ao.uri }
        let(:total_batches) { 3 }
        let(:child_count) { child_count_on_expand_before_lazy_loading_batches }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'parent node has not been expanded'

        describe 'expands' do
          it_behaves_like 'parent node expands on expand button click'
          it_behaves_like 'parent node expands on title click'
          it_behaves_like 'parent node expands on keydown'
        end

        describe 'collapses' do
          it_behaves_like 'parent node collapses on expand button click'
          it_behaves_like 'parent node collapses on keydown'
        end

        describe 'after initial expansion' do
          before do
            node.find(':scope > .node-row .node-expand').click
            wait_for_ajax
          end

          let(:child_list) { node.find(':scope > .node-children') }
          let(:batches_not_yet_loaded) { [1, 2] }

          it_behaves_like 'child list has an observer node for the second batch'
          it_behaves_like 'child list has the correct number of batch placeholders'
          it_behaves_like 'child list lazy loads the remaining batches of children on scroll'
        end
      end

      describe 'with four batches of children' do
        include_context 'parent node with 3*BATCH_SIZE+1 children'
        let(:total_child_count) { BATCH_SIZE * 3 + 1 }
        child_count_on_expand_before_lazy_loading_batches = BATCH_SIZE
        let(:node) { tree.find("#archival_object_#{parent_ao.id}") }
        let(:expected_uri) { parent_ao.uri }
        let(:total_batches) { 4 }
        let(:child_count) { child_count_on_expand_before_lazy_loading_batches }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'parent node has not been expanded'

        describe 'expands' do
          it_behaves_like 'parent node expands on expand button click'
          it_behaves_like 'parent node expands on title click'
          it_behaves_like 'parent node expands on keydown'
        end

        describe 'collapses' do
          it_behaves_like 'parent node collapses on expand button click'
          it_behaves_like 'parent node collapses on keydown'
        end

        describe 'after initial expansion' do
          before do
            node.find(':scope > .node-row .node-expand').click
            wait_for_ajax
          end

          let(:child_list) { node.find(':scope > .node-children') }
          let(:batches_not_yet_loaded) { [1, 2, 3] }

          it_behaves_like 'child list has an observer node for the second batch'
          it_behaves_like 'child list has the correct number of batch placeholders'
          it_behaves_like 'child list lazy loads the remaining batches of children on scroll'
        end
      end

      context 'after batches are lazy loaded' do
        include_context 'parent node with 3*BATCH_SIZE+1 children'
        let(:total_child_count) { BATCH_SIZE * 3 + 1 }
        let(:node) { tree.find("#archival_object_#{parent_ao.id}") }

        before(:each) do
          node.find(':scope > .node-row .node-expand').click
          wait_for_ajax
        end

        let(:child_list) { node.find(':scope > .node-children') }
        let(:child_count_on_initial_expand) { BATCH_SIZE }
        let(:batches_to_load) { [1, 2, 3] }

        it_behaves_like 'collapsing hides all previously loaded children'
        it_behaves_like 'expanding shows all previously loaded children'
      end
    end

    context 'leaf node' do
      let(:node) { tree.find("#archival_object_#{ao.id}") }
      let(:expected_uri) { ao.uri }

      include_examples 'basic node markup'
      it_behaves_like 'node has no children'
    end

    describe 'columns' do
      before(:each) do
        allow(AppConfig).to receive(:[]).and_call_original
        allow(AppConfig).to receive(:[])
          .with(:display_identifiers_in_largetree_container)
          .and_return(display_identifiers)
      end

      context 'when AppConfig[:display_identifiers_in_largetree_container] is false' do
        let(:display_identifiers) { false }

        include_examples 'renders base columns'
        include_examples 'identifier column hidden'
      end

      context 'when AppConfig[:display_identifiers_in_largetree_container] is true' do
        let(:display_identifiers) { true }

        include_examples 'renders base columns'
        include_examples 'identifier column visible'
      end
    end

    describe 'suppressed badge' do
      let!(:suppressed_ao) do
        create(
          :archival_object,
          resource: { 'ref' => resource.uri },
          title: "Suppressed AO #{now}"
        ).tap { |obj| obj.set_suppressed(true) }
      end

      it 'is shown only for suppressed records' do
        visit "/resources/#{resource.id}"
        badge_selector = '#infinite-tree-container .record-title .badge'
        badge = find(badge_selector, text: 'Suppressed', match: :first)
        badge_parent = badge.find(:xpath, '..')

        expect(page).to have_css(badge_selector, text: 'Suppressed', count: 1)
        expect(badge_parent['title']).to eq(suppressed_ao.title)
      end
    end

    describe 'mixed content in title column' do
      let(:resource) do
        create(
          :resource,
          title: 'This is <emph>a mixed content</emph> title'
        )
      end

      let!(:mixed_content_ao) do
        create(
          :archival_object,
          resource: { 'ref' => resource.uri },
          title: 'This is <emph render="italic">another mixed content</emph> title'
        )
      end

      let!(:plain_ao) do
        create(
          :archival_object,
          resource: { 'ref' => resource.uri },
          title: 'This is not a mixed content title'
        )
      end

      let(:allow_mixed_content_title_fields) { true }

      before(:each) do
        allow(AppConfig).to receive(:[]).and_call_original
        allow(AppConfig)
          .to receive(:[])
          .with(:allow_mixed_content_title_fields)
          .and_return(allow_mixed_content_title_fields)
      end

      it 'renders titles with mixed content appropriately' do
        tree

        resource_node = find("#resource_#{resource.id}")
        expect(resource_node).to have_css('.node-body[title="This is a mixed content title"]')
        resource_mixed_span = resource_node.find('.node-row span.emph.render-none')
        expect(resource_mixed_span).to have_text('a mixed content')

        ao1_node = find("#archival_object_#{mixed_content_ao.id}")
        expect(ao1_node).to have_css('.node-row > .node-body[title="This is another mixed content title"]')
        ao1_mixed_span = ao1_node.find('.node-row span.emph.render-italic')
        expect(ao1_mixed_span).to have_text('another mixed content')

        ao2_node = find("#archival_object_#{plain_ao.id}")
        ao2_title = ao2_node.find('.node-row .record-title')
        expect(ao2_title).not_to have_css('span')
        expect(ao2_title).to have_text('This is not a mixed content title')
      end
    end
  end

  context 'on the digital objects show view' do
    shared_examples 'renders appropriate columns' do
      it 'renders the appropriate columns' do
        aggregate_failures do
          expect(tree).to have_css('[data-column="title"]', visible: true)
          expect(tree).to have_css('[data-column="type"]', visible: :all)
          expect(tree).to have_css('[data-column="container"]', visible: :all)
        end
      end
    end

    let(:digital_object) { create(:digital_object, title: "Digital Object #{now}", digital_object_type: 'mixed_materials') }
    let(:doc) { create(:digital_object_component, digital_object: { 'ref' => digital_object.uri }, title: "Digital Object Component #{now}") }

    before(:each) do
      set_repo(repo)
      login_admin
      select_repository(repo)
      doc
    end

    subject(:tree) do
      visit "/digital_objects/#{digital_object.id}"
      wait_for_ajax
      find('.infinite-tree')
    end

    let(:container) { find('#infinite-tree-container') }

    describe 'tree list' do
      it 'has role tree' do
        expect(tree['role']).to eq('tree')
      end

      it 'has one child' do
        expect(tree).to have_css(':scope > li', count: 1)
        expect(tree).to have_css(':scope > li.root.node')
      end
    end

    context 'root node' do
      describe 'with no children' do
        let(:doc) { nil }
        let(:digital_object) { create(:digital_object, title: "Digital Object #{now}", digital_object_type: 'mixed_materials') }
        let(:node) { tree.find("#digital_object_#{digital_object.id}") }
        let(:expected_uri) { digital_object.uri }

        include_examples 'basic node markup'
        it_behaves_like 'node has no children'
      end

      describe 'with one child' do
        let(:node) { tree.find("#digital_object_#{digital_object.id}") }
        let(:expected_uri) { digital_object.uri }
        let(:total_batches) { 1 }
        let(:child_count) { 1 }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'node has X children visible'
      end

      describe 'with ten children' do
        total_child_count = 10
        let!(:children) do
          (total_child_count - 1).times.map do |i|
            create(
              :digital_object_component,
              digital_object: { 'ref' => digital_object.uri },
              title: "DOC #{i + 1} #{now}"
            )
          end
        end
        let(:node) { tree.find("#digital_object_#{digital_object.id}") }
        let(:expected_uri) { digital_object.uri }
        let(:total_batches) { 1 }
        let(:child_count) { total_child_count }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'node has X children visible'
      end

      describe 'with two batches of children' do
        let(:total_child_count) { BATCH_SIZE + 1 }
        child_count_before_lazy_loading_batches = BATCH_SIZE
        let!(:children) do
          (total_child_count - 1).times.map do |i|
            create(
              :digital_object_component,
              digital_object: { 'ref' => digital_object.uri },
              title: "DOC #{i + 1} #{now}"
            )
          end
        end
        let(:node) { tree.find("#digital_object_#{digital_object.id}") }
        let(:expected_uri) { digital_object.uri }
        let(:child_list) { node.find(':scope > .node-children') }
        let(:total_batches) { 2 }
        let(:child_count) { child_count_before_lazy_loading_batches }
        let(:batches_not_yet_loaded) { [1] }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'node has X children visible'
        it_behaves_like 'child list has an observer node for the second batch'
        it_behaves_like 'child list has the correct number of batch placeholders'
        it_behaves_like 'child list lazy loads the remaining batches of children on scroll'
      end
    end

    context 'parent node' do
      describe 'with one child' do
        total_child_count = 1
        child_count_on_expand = total_child_count
        let!(:child) do
          create(
            :digital_object_component,
            digital_object: { 'ref' => digital_object.uri },
            parent: { 'ref' => doc.uri },
            title: "Child of DOC #{now}"
          )
        end
        let(:node) { tree.find("#digital_object_component_#{doc.id}") }
        let(:expected_uri) { doc.uri }
        let(:total_batches) { 1 }
        let(:child_count) { child_count_on_expand }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'parent node has not been expanded'

        describe 'expands' do
          it_behaves_like 'parent node expands on expand button click'
          it_behaves_like 'parent node expands on title click'
          it_behaves_like 'parent node expands on keydown'
        end

        describe 'collapses' do
          it_behaves_like 'parent node collapses on expand button click'
          it_behaves_like 'parent node collapses on keydown'
        end
      end

      describe 'with ten children' do
        total_child_count = 10
        child_count_on_expand = total_child_count
        let!(:children) do
          total_child_count.times.map do |i|
            create(
              :digital_object_component,
              digital_object: { 'ref' => digital_object.uri },
              parent: { 'ref' => doc.uri },
              title: "Child of DOC #{now}"
            )
          end
        end
        let(:node) { tree.find("#digital_object_component_#{doc.id}") }
        let(:expected_uri) { doc.uri }
        let(:total_batches) { 1 }
        let(:child_count) { child_count_on_expand }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'parent node has not been expanded'

        describe 'expands' do
          it_behaves_like 'parent node expands on expand button click'
          it_behaves_like 'parent node expands on title click'
          it_behaves_like 'parent node expands on keydown'
        end

        describe 'collapses' do
          it_behaves_like 'parent node collapses on expand button click'
          it_behaves_like 'parent node collapses on keydown'
        end
      end

      describe 'with two batches of children' do
        let(:total_child_count) { BATCH_SIZE + 1 }
        child_count_on_expand_before_lazy_loading_batches = BATCH_SIZE
        let!(:children) do
          total_child_count.times.map do |i|
            create(
              :digital_object_component,
              digital_object: { 'ref' => digital_object.uri },
              parent: { 'ref' => doc.uri },
              title: "Child of DOC #{now}"
            )
          end
        end
        let(:node) { tree.find("#digital_object_component_#{doc.id}") }
        let(:expected_uri) { doc.uri }
        let(:total_batches) { 2 }
        let(:child_count) { child_count_on_expand_before_lazy_loading_batches }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'parent node has not been expanded'

        describe 'expands' do
          it_behaves_like 'parent node expands on expand button click'
          it_behaves_like 'parent node expands on title click'
          it_behaves_like 'parent node expands on keydown'
        end

        describe 'collapses' do
          it_behaves_like 'parent node collapses on expand button click'
          it_behaves_like 'parent node collapses on keydown'
        end

        describe 'after initial expansion' do
          before do
            node.find(':scope > .node-row .node-expand').click
            wait_for_ajax
          end

          let(:child_list) { node.find(':scope > .node-children') }
          let(:batches_not_yet_loaded) { [1] }

          it_behaves_like 'child list has an observer node for the second batch'
          it_behaves_like 'child list has the correct number of batch placeholders'
          it_behaves_like 'child list lazy loads the remaining batches of children on scroll'
        end
      end
    end

    context 'leaf node' do
      let(:node) { tree.find("#digital_object_component_#{doc.id}") }
      let(:expected_uri) { doc.uri }

      include_examples 'basic node markup'
      it_behaves_like 'node has no children'
    end

    describe 'columns' do
      include_examples 'renders appropriate columns'
    end

    describe 'suppressed badge' do
      let!(:suppressed_doc) do
        create(
          :digital_object_component,
          digital_object: { 'ref' => digital_object.uri },
          title: "Suppressed DOC #{now}"
        ).tap { |obj| obj.set_suppressed(true) }
      end

      it 'is shown only for suppressed records' do
        visit "/digital_objects/#{digital_object.id}"
        badge_selector = '#infinite-tree-container .record-title .badge'
        badge = find(badge_selector, text: 'Suppressed', match: :first)
        badge_parent = badge.find(:xpath, '..')

        expect(page).to have_css(badge_selector, text: 'Suppressed', count: 1)
        expect(badge_parent['title']).to eq(suppressed_doc.title)
      end
    end

    describe 'mixed content in title column' do
      let(:digital_object) do
        create(
          :digital_object,
          title: 'This is <emph>a mixed content</emph> title',
          digital_object_type: 'mixed_materials'
        )
      end

      let!(:mixed_content_doc) do
        create(
          :digital_object_component,
          digital_object: { 'ref' => digital_object.uri },
          title: 'This is <emph render="italic">another mixed content</emph> title'
        )
      end

      let!(:plain_doc) do
        create(
          :digital_object_component,
          digital_object: { 'ref' => digital_object.uri },
          title: 'This is not a mixed content title'
        )
      end

      let(:allow_mixed_content_title_fields) { true }

      before(:each) do
        allow(AppConfig).to receive(:[]).and_call_original
        allow(AppConfig)
          .to receive(:[])
          .with(:allow_mixed_content_title_fields)
          .and_return(allow_mixed_content_title_fields)
      end

      it 'renders titles with mixed content appropriately' do
        tree

        digital_object_node = find("#digital_object_#{digital_object.id}")
        expect(digital_object_node).to have_css('.node-body[title="This is a mixed content title"]')
        digital_object_mixed_span = digital_object_node.find('.node-row span.emph.render-none')
        expect(digital_object_mixed_span).to have_text('a mixed content')

        doc1_node = find("#digital_object_component_#{mixed_content_doc.id}")
        expect(doc1_node).to have_css('.node-row > .node-body[title="This is another mixed content title"]')
        doc1_mixed_span = doc1_node.find('.node-row span.emph.render-italic')
        expect(doc1_mixed_span).to have_text('another mixed content')

        doc2_node = find("#digital_object_component_#{plain_doc.id}")
        doc2_title = doc2_node.find('.node-row .record-title')
        expect(doc2_title).not_to have_css('span')
        expect(doc2_title).to have_text('This is not a mixed content title')
      end
    end
  end

  context 'on the classifications show view' do
    shared_examples 'renders appropriate columns' do
      it 'renders the appropriate columns' do
        aggregate_failures do
          expect(tree).to have_css('[data-column="title"]', visible: true)
        end
      end
    end

    let(:classification) { create(:classification, title: "Classification #{now}", identifier: "CLASS#{now}") }
    let(:ct) { create(:classification_term, classification: { 'ref' => classification.uri }, title: "Classification Term #{now}", identifier: "CT#{now}") }

    before(:each) do
      set_repo(repo)
      login_admin
      select_repository(repo)
      ct
    end

    subject(:tree) do
      visit "/classifications/#{classification.id}"
      wait_for_ajax
      find('.infinite-tree')
    end

    let(:container) { find('#infinite-tree-container') }

    describe 'tree list' do
      it 'has role tree' do
        expect(tree['role']).to eq('tree')
      end

      it 'has one child' do
        expect(tree).to have_css(':scope > li', count: 1)
        expect(tree).to have_css(':scope > li.root.node')
      end
    end

    context 'root node' do
      describe 'with no children' do
        let(:ct) { nil }
        let(:classification) { create(:classification, title: "Classification #{now}", identifier: "CLASS#{now}") }
        let(:node) { tree.find("#classification_#{classification.id}") }
        let(:expected_uri) { classification.uri }

        include_examples 'basic node markup'
        it_behaves_like 'node has no children'
      end

      describe 'with one child' do
        let(:node) { tree.find("#classification_#{classification.id}") }
        let(:expected_uri) { classification.uri }
        let(:total_batches) { 1 }
        let(:child_count) { 1 }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'node has X children visible'
      end

      describe 'with ten children' do
        total_child_count = 10
        let!(:children) do
          (total_child_count - 1).times.map do |i|
            create(
              :classification_term,
              classification: { 'ref' => classification.uri },
              title: "CT #{i + 1} #{now}",
              identifier: "CT#{i + 1}#{now}"
            )
          end
        end
        let(:node) { tree.find("#classification_#{classification.id}") }
        let(:expected_uri) { classification.uri }
        let(:total_batches) { 1 }
        let(:child_count) { total_child_count }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'node has X children visible'
      end

      describe 'with two batches of children' do
        let(:total_child_count) { BATCH_SIZE + 1 }
        child_count_before_lazy_loading_batches = BATCH_SIZE
        let!(:children) do
          (total_child_count - 1).times.map do |i|
            create(
              :classification_term,
              classification: { 'ref' => classification.uri },
              title: "CT #{i + 1} #{now}",
              identifier: "CT#{i + 1}#{now}"
            )
          end
        end
        let(:node) { tree.find("#classification_#{classification.id}") }
        let(:expected_uri) { classification.uri }
        let(:child_list) { node.find(':scope > .node-children') }
        let(:total_batches) { 2 }
        let(:child_count) { child_count_before_lazy_loading_batches }
        let(:batches_not_yet_loaded) { [1] }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'node has X children visible'
        it_behaves_like 'child list has an observer node for the second batch'
        it_behaves_like 'child list has the correct number of batch placeholders'
        it_behaves_like 'child list lazy loads the remaining batches of children on scroll'
      end
    end

    context 'parent node' do
      describe 'with one child' do
        total_child_count = 1
        child_count_on_expand = total_child_count
        let!(:child) do
          create(
            :classification_term,
            classification: { 'ref' => classification.uri },
            parent: { 'ref' => ct.uri },
            title: "Child of CT #{now}",
            identifier: "CHILD-CT#{now}"
          )
        end
        let(:node) { tree.find("#classification_term_#{ct.id}") }
        let(:expected_uri) { ct.uri }
        let(:total_batches) { 1 }
        let(:child_count) { child_count_on_expand }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'parent node has not been expanded'

        describe 'expands' do
          it_behaves_like 'parent node expands on expand button click'
          it_behaves_like 'parent node expands on title click'
          it_behaves_like 'parent node expands on keydown'
        end

        describe 'collapses' do
          it_behaves_like 'parent node collapses on expand button click'
          it_behaves_like 'parent node collapses on keydown'
        end
      end

      describe 'with ten children' do
        total_child_count = 10
        child_count_on_expand = total_child_count
        let!(:children) do
          total_child_count.times.map do |i|
            create(
              :classification_term,
              classification: { 'ref' => classification.uri },
              parent: { 'ref' => ct.uri },
              title: "Child #{i + 1} of CT #{now}",
              identifier: "CHILD#{i + 1}-CT#{now}"
            )
          end
        end
        let(:node) { tree.find("#classification_term_#{ct.id}") }
        let(:expected_uri) { ct.uri }
        let(:total_batches) { 1 }
        let(:child_count) { child_count_on_expand }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'parent node has not been expanded'

        describe 'expands' do
          it_behaves_like 'parent node expands on expand button click'
          it_behaves_like 'parent node expands on title click'
          it_behaves_like 'parent node expands on keydown'
        end

        describe 'collapses' do
          it_behaves_like 'parent node collapses on expand button click'
          it_behaves_like 'parent node collapses on keydown'
        end
      end

      describe 'with two batches of children' do
        let(:total_child_count) { BATCH_SIZE + 1 }
        child_count_on_expand_before_lazy_loading_batches = BATCH_SIZE
        let!(:children) do
          total_child_count.times.map do |i|
            create(
              :classification_term,
              classification: { 'ref' => classification.uri },
              parent: { 'ref' => ct.uri },
              title: "Child #{i + 1} of CT #{now}",
              identifier: "CHILD#{i + 1}-CT#{now}"
            )
          end
        end
        let(:node) { tree.find("#classification_term_#{ct.id}") }
        let(:expected_uri) { ct.uri }
        let(:total_batches) { 2 }
        let(:child_count) { child_count_on_expand_before_lazy_loading_batches }

        include_examples 'basic node markup'
        it_behaves_like 'node has correct data-total-child-batches attribute'
        it_behaves_like 'parent node has not been expanded'

        describe 'expands' do
          it_behaves_like 'parent node expands on expand button click'
          it_behaves_like 'parent node expands on title click'
          it_behaves_like 'parent node expands on keydown'
        end

        describe 'collapses' do
          it_behaves_like 'parent node collapses on expand button click'
          it_behaves_like 'parent node collapses on keydown'
        end

        describe 'after initial expansion' do
          before do
            node.find(':scope > .node-row .node-expand').click
            wait_for_ajax
          end

          let(:child_list) { node.find(':scope > .node-children') }
          let(:batches_not_yet_loaded) { [1] }

          it_behaves_like 'child list has an observer node for the second batch'
          it_behaves_like 'child list has the correct number of batch placeholders'
          it_behaves_like 'child list lazy loads the remaining batches of children on scroll'
        end
      end
    end

    context 'leaf node' do
      let(:node) { tree.find("#classification_term_#{ct.id}") }
      let(:expected_uri) { ct.uri }

      include_examples 'basic node markup'
      it_behaves_like 'node has no children'
    end

    describe 'columns' do
      include_examples 'renders appropriate columns'
    end
  end
end
