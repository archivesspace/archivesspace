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
      @ao1, @ao2, @ao3, @ao4, @ao5, @ao6, @ao7 = batch_create_archival_objects(7, resource: @resource)

      @resource2 = create(:resource, publish: true)
      @resource3 = create(:resource, publish: true)

      # Child nodes in tree order, keyed by the name of their parent
      @children = {
        'resource' => [@ao1, @ao2, @ao3, @ao4, @ao5, @ao6, @ao7], # 1 batch
        'ao1' => batch_create_archival_objects(1, resource: @resource, parent: @ao1), # 1 batch with a single node
        'ao2' => batch_create_archival_objects(5, resource: @resource, parent: @ao2), # 1 batch with multiple nodes
        'ao3' => batch_create_archival_objects(31, resource: @resource, parent: @ao3), # 2 batches
        'ao4' => batch_create_archival_objects(61, resource: @resource, parent: @ao4), # 3 batches
        'ao5' => batch_create_archival_objects(91, resource: @resource, parent: @ao5), # 4 batches
        'resource2' => batch_create_archival_objects(31, resource: @resource2), # 2 batches
        'resource3' => batch_create_archival_objects(61, resource: @resource3) # 3 batches
      }

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

    # The list's items in order: node ids, and "placeholder N" for batch N
    # not yet loaded.  Read in one call, rather than one query per node.
    def rendered_children(list)
      page.evaluate_script(<<~JS, list)
        Array.from(arguments[0].children).map(item =>
          item.hasAttribute('data-batch-placeholder')
            ? `placeholder ${item.getAttribute('data-batch-placeholder')}`
            : item.id
        )
      JS
    end

    def expected_children(parent, populated_batches)
      node_ids = @children.fetch(parent).map { |ao| "archival_object_#{ao.id}" }
      batches = node_ids.each_slice(@tree_batch_size).to_a

      batches.each_index.flat_map do |batch|
        populated_batches.include?(batch) ? batches[batch] : ["placeholder #{batch}"]
      end
    end

    shared_examples 'uri fragment batch rendering' do
      it 'shows the node of interest among its loaded siblings, and loads the remaining batches on scroll' do
        aggregate_failures 'on page load' do
          expect(node.find('& > .node-row')).to appear_in_tree_viewport
          expect(parent_list).to have_css('.node', count: expected_node_count_on_page_load)
          expect(rendered_children(parent_list)).to eq expected_children(parent, expected_populated_batches)
        end

        unless expected_batch_placeholders.empty?
          container = page.find('#infinite-tree-container')

          expected_batch_placeholders.each do |batch_offset|
            observer_node = parent_list.first("[data-observe-offset='#{batch_offset}']")
            container.scroll_to(observer_node, align: :center)
          end

          aggregate_failures 'after scrolling' do
            expect(parent_list).to have_css('.node', count: total_nodes)
            expect(rendered_children(parent_list)).to eq expected_children(parent, (0...total_batches).to_a)
          end
        end
      end
    end

    context 'when loading a page with a URI fragment' do
      let(:total_nodes) { @children.fetch(parent).length }
      let(:total_batches) { (total_nodes / @tree_batch_size.to_f).ceil }

      context 'when the target node is not the root node' do
        let(:node_record_id) { @children.fetch(parent)[node_position - 1].id }

        let!(:node) do
          visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization#tree::archival_object_#{node_record_id}"

          find("#archival_object_#{node_record_id}.current")
        end

        let(:parent_list) { node.find(:xpath, '..') }

        context "the target node's parent has 1 batch of child nodes" do
          let(:expected_populated_batches) { [0] }
          let(:expected_batch_placeholders) { [] }

          context 'containing a single node' do
            let(:parent) { 'ao1' }
            let(:expected_node_count_on_page_load) { 1 }
            let(:node_position) { 1 }

            it_behaves_like 'uri fragment batch rendering'
          end

          context 'containing multiple nodes' do
            let(:parent) { 'ao2' }
            let(:expected_node_count_on_page_load) { 5 }
            let(:node_position) { 2 }

            it_behaves_like 'uri fragment batch rendering'
          end
        end

        context "the target node's parent has 2 batches of child nodes" do
          let(:parent) { 'ao3' }
          let(:expected_node_count_on_page_load) { 31 }
          let(:expected_populated_batches) { [0, 1] }
          let(:expected_batch_placeholders) { [] }

          context 'and the target node is in the first batch' do
            let(:node_position) { 15 }

            it_behaves_like 'uri fragment batch rendering'
          end

          context 'and the target node is in the second batch' do
            let(:node_position) { 31 }

            it_behaves_like 'uri fragment batch rendering'
          end
        end

        context "the target node's parent has 3 batches of child nodes" do
          let(:parent) { 'ao4' }

          context 'and the target node is in the first batch' do
            let(:expected_node_count_on_page_load) { 60 }
            let(:expected_populated_batches) { [0, 1] }
            let(:expected_batch_placeholders) { [2] }
            let(:node_position) { 15 }

            it_behaves_like 'uri fragment batch rendering'
          end

          context 'and the target node is in the second batch' do
            let(:expected_node_count_on_page_load) { 61 }
            let(:expected_populated_batches) { [0, 1, 2] }
            let(:expected_batch_placeholders) { [] }
            let(:node_position) { 45 }

            it_behaves_like 'uri fragment batch rendering'
          end

          context 'and the target node is in the third batch' do
            let(:expected_node_count_on_page_load) { 61 }
            let(:expected_populated_batches) { [0, 1, 2] }
            let(:expected_batch_placeholders) { [] }
            let(:node_position) { 61 }

            it_behaves_like 'uri fragment batch rendering'
          end
        end

        context "the target node's parent has 4 batches of child nodes" do
          let(:parent) { 'ao5' }

          context 'and the target node is in the first batch' do
            let(:expected_node_count_on_page_load) { 60 }
            let(:expected_populated_batches) { [0, 1] }
            let(:expected_batch_placeholders) { [2, 3] }
            let(:node_position) { 25 }

            it_behaves_like 'uri fragment batch rendering'
          end

          context 'and the target node is in the second batch' do
            let(:expected_node_count_on_page_load) { 90 }
            let(:expected_populated_batches) { [0, 1, 2] }
            let(:expected_batch_placeholders) { [3] }
            let(:node_position) { 45 }

            it_behaves_like 'uri fragment batch rendering'
          end

          context 'and the target node is in the third batch' do
            let(:expected_node_count_on_page_load) { 91 }
            let(:expected_populated_batches) { [0, 1, 2, 3] }
            let(:expected_batch_placeholders) { [] }
            let(:node_position) { 75 }

            it_behaves_like 'uri fragment batch rendering'
          end

          context 'and the target node is in the fourth batch' do
            let(:expected_node_count_on_page_load) { 61 }
            let(:expected_populated_batches) { [0, 2, 3] }
            let(:expected_batch_placeholders) { [1] }
            let(:node_position) { 91 }

            it_behaves_like 'uri fragment batch rendering'
          end
        end
      end

      context 'when the target node is the root node' do
        let!(:node) do
          visit "/repositories/#{@repo.id}/resources/#{resource_id}/collection_organization#tree::resource_#{resource_id}"

          find(".infinite-tree .root.current")
        end

        let(:parent_list) { node.find('& > .node-children') }
        let(:expected_populated_batches) { [0] }

        context 'when the root node has 1 batch of child nodes' do
          let(:resource_id) { @resource.id }
          let(:parent) { 'resource' }
          let(:expected_node_count_on_page_load) { 7 }
          let(:expected_batch_placeholders) { [] }

          it_behaves_like 'uri fragment batch rendering'
        end

        context 'when the root node has 2 batches of child nodes' do
          let(:resource_id) { @resource2.id }
          let(:parent) { 'resource2' }
          let(:expected_node_count_on_page_load) { 30 }
          let(:expected_batch_placeholders) { [1] }

          it_behaves_like 'uri fragment batch rendering'
        end

        context 'when the root node has 3 batches of child nodes' do
          let(:resource_id) { @resource3.id }
          let(:parent) { 'resource3' }
          let(:expected_node_count_on_page_load) { 30 }
          let(:expected_batch_placeholders) { [1, 2] }

          it_behaves_like 'uri fragment batch rendering'
        end
      end
    end
  end
end
