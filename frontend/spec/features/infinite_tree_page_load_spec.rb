require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree Page Load', js: true do
  before(:all) do
    @repo = create(:repo, repo_code: "collection_organization_test_#{Time.now.to_i}")
    set_repo(@repo)

    @tree_batch_size = Rails.configuration.infinite_tree_batch_size
  end

  before(:each) do
    login_admin_and_select_repository(@repo)
  end

  RSpec::Matchers.define :appear_in_tree_viewport do
    match do |node|
      tree = find('#infinite-tree-container')
      # Documented JS exception: viewport geometry check (no Capybara equivalent)
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

  def expected_children(children, child_type, populated_batches)
    batches = children.map { |child| "#{child_type}_#{child.id}" }.each_slice(@tree_batch_size).to_a

    batches.each_index.flat_map do |batch|
      populated_batches.include?(batch) ? batches[batch] : ["placeholder #{batch}"]
    end
  end

  # Checks the target node and its loaded siblings on page load, then scrolls
  # through the placeholders and checks that every batch has loaded in order.
  def expect_uri_fragment_batch_rendering(node, parent_list, children, child_type, node_count, populated_batches)
    total_batches = (children.length / @tree_batch_size.to_f).ceil

    aggregate_failures 'on page load' do
      expect(node.find(':scope > .node-row')).to appear_in_tree_viewport
      expect(page).to have_css('#infinite-tree-container .node.current', count: 1, visible: :all)
      expect(parent_list).to have_css('.node', count: node_count)
      expect(rendered_children(parent_list)).to eq expected_children(children, child_type, populated_batches)
    end

    placeholders = (0...total_batches).to_a - populated_batches
    return if placeholders.empty?

    container = page.find('#infinite-tree-container')
    placeholders.each do |batch_offset|
      observer_node = parent_list.first("[data-observe-offset='#{batch_offset}']")
      container.scroll_to(observer_node, align: :center)
    end

    aggregate_failures 'after scrolling' do
      expect(parent_list).to have_css('.node', count: children.length)
      expect(rendered_children(parent_list)).to eq expected_children(children, child_type, (0...total_batches).to_a)
    end
  end

  [
    {
      name: 'Resources',
      root_type: 'resource',
      child_type: 'archival_object',
      root_attrs: {},
      top_level_count: 7,
      # Sibling counts of the child lists nested under the first top-level
      # nodes, and of the child lists of further root records.
      nested_counts: [1, 5, 31, 61, 91],
      other_root_counts: [31, 61, 91],
      # [siblings, target position, nodes rendered on page load, batches populated on page load]
      child_scenarios: [
        [1, 1, 1, [0]],
        [5, 2, 5, [0]],
        [31, 15, 31, [0, 1]],
        [31, 31, 31, [0, 1]],
        [61, 15, 60, [0, 1]],
        [61, 45, 61, [0, 1, 2]],
        [61, 61, 61, [0, 1, 2]],
        [91, 25, 60, [0, 1]],
        [91, 45, 90, [0, 1, 2]],
        [91, 75, 91, [0, 1, 2, 3]],
        [91, 91, 61, [0, 2, 3]]
      ],
      # [siblings, nodes rendered on page load]; only batch 0 is populated
      root_scenarios: [[7, 7], [31, 30], [61, 30], [91, 30]]
    },
    {
      name: 'Digital Objects',
      root_type: 'digital_object',
      child_type: 'digital_object_component',
      root_attrs: { digital_object_type: 'mixed_materials' },
      top_level_count: 5,
      nested_counts: [1, 5, 31],
      other_root_counts: [31],
      child_scenarios: [
        [1, 1, 1, [0]],
        [5, 2, 5, [0]],
        [31, 15, 31, [0, 1]],
        [31, 31, 31, [0, 1]]
      ],
      root_scenarios: [[5, 5], [31, 30]]
    },
    {
      name: 'Classifications',
      root_type: 'classification',
      child_type: 'classification_term',
      root_attrs: {},
      top_level_count: 3,
      nested_counts: [1, 5, 31],
      other_root_counts: [31],
      child_scenarios: [
        [1, 1, 1, [0]],
        [5, 2, 5, [0]],
        [31, 15, 31, [0, 1]],
        [31, 31, 31, [0, 1]]
      ],
      root_scenarios: [[3, 3], [31, 30]]
    }
  ].each do |hierarchy|
    context hierarchy[:name] do
      root_type = hierarchy[:root_type]
      child_type = hierarchy[:child_type]

      before(:all) do
        create_root = -> { create(root_type.to_sym, title: "#{hierarchy[:name]} root", publish: true, **hierarchy[:root_attrs]) }
        create_children = lambda do |count, root, parent = nil|
          batch_create_tree_children(child_type.to_sym, count, root_key: root_type.to_sym,
                                                               root: root, parent: parent, publish: true) do |i|
            { title: "Child #{i + 1}" }
          end
        end

        @root = create_root.call
        top_level = create_children.call(hierarchy[:top_level_count], @root)

        # Child lists keyed by sibling count, with the root record they belong to
        @child_lists = { hierarchy[:top_level_count] => [@root, top_level] }
        @nested_child_lists = {}
        hierarchy[:nested_counts].each_with_index do |count, i|
          @nested_child_lists[count] = create_children.call(count, @root, top_level[i])
        end
        hierarchy[:other_root_counts].each do |count|
          root = create_root.call
          @child_lists[count] = [root, create_children.call(count, root)]
        end
      end

      context 'when loading a page with a URI fragment' do
        hierarchy[:child_scenarios].each do |siblings, position, node_count, populated_batches|
          context "when the target node is #{position} of #{siblings} sibling nodes" do
            it 'shows the node among its loaded siblings, and loads the remaining batches on scroll' do
              children = @nested_child_lists.fetch(siblings)
              target = children[position - 1]

              visit "/#{root_type}s/#{@root.id}/#tree::#{child_type}_#{target.id}"
              node = find("##{child_type}_#{target.id}.current")

              expect_uri_fragment_batch_rendering(node, node.find(:xpath, '..'), children, child_type,
                                                  node_count, populated_batches)
            end
          end
        end

        hierarchy[:root_scenarios].each do |siblings, node_count|
          context "when the target node is the root node, with #{siblings} child nodes" do
            it 'shows the root with its first batch of children, and loads the remaining batches on scroll' do
              root, children = @child_lists.fetch(siblings)

              visit "/#{root_type}s/#{root.id}#tree::#{root_type}_#{root.id}"
              node = find('.infinite-tree .root.current')

              expect_uri_fragment_batch_rendering(node, node.find(':scope > .node-children'), children, child_type,
                                                  node_count, [0])
            end
          end
        end

        let(:show_path) { "/#{root_type}s/#{@root.id}" }
        let(:root_type) { root_type }
        let(:root_id) { @root.id }
        let(:child_type) { child_type }

        it_behaves_like 'normalizing invalid location hashes on the show view'
      end
    end
  end
end
