# Shared examples for Infinite Tree functionality across resources,
# digital_objects, and classifications

RSpec.shared_examples 'infinite tree record show view' do |record_config|
  let(:record_type) { record_config[:record_type] }
  let(:child_type) { record_config[:child_type] }
  let(:root_factory) { record_config[:root_factory] }
  let(:child_factory) { record_config[:child_factory] }
  let(:root_relationship_key) { record_config[:root_relationship_key] }
  let(:show_path) { record_config[:show_path] }
  let(:columns_config) { record_config[:columns] }
  let(:max_batch_scenarios) { record_config[:max_batch_scenarios] || 4 }
  let(:additional_root_attrs) do
    attrs = record_config[:additional_root_attrs]
    attrs.respond_to?(:call) ? attrs.call(unique_id) : (attrs || {})
  end
  let(:additional_child_attrs) do
    attrs = record_config[:additional_child_attrs]
    attrs.respond_to?(:call) ? attrs.call(unique_id) : (attrs || {})
  end

  # Common setup that all record types need
  let(:now) { Time.now.to_i }
  let(:unique_id) { "#{record_type}_#{now}_#{rand(10000)}" }
  let(:repo) { create(:repo, repo_code: "infinite_tree_test_#{unique_id}") }

  before(:each) do
    set_repo(repo)
    login_admin
    select_repository(repo)
  end

  let(:container) { find('#infinite-tree-container') }

  # Basic tree setup for tree list tests - uses a simple root record with one child
  let(:basic_root_record) { create(root_factory, { title: "#{record_type.humanize} #{unique_id}" }.merge(additional_root_attrs)) }
  let(:basic_child_record) do
    create(child_factory, {
      root_relationship_key => { 'ref' => basic_root_record.uri },
      title: "#{child_type.humanize} #{unique_id}"
    }.merge(additional_child_attrs))
  end

  subject(:tree) do
    basic_child_record # Ensure child exists
    visit show_path.call(basic_root_record.id)
    wait_for_ajax
    find('.infinite-tree')
  end

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
    it_behaves_like 'root node with no children'
    it_behaves_like 'root node with one child'
    it_behaves_like 'root node with ten children'
    it_behaves_like 'root node with two batches of children'

    if record_config[:max_batch_scenarios] >= 3
      it_behaves_like 'root node with three batches of children'
    end
    
    if record_config[:max_batch_scenarios] >= 4
      it_behaves_like 'root node with four batches of children'
    end
  end

  context 'parent node' do
    it_behaves_like 'parent node with one child'
    it_behaves_like 'parent node with ten children'
    it_behaves_like 'parent node with two batches of children'
    
    if record_config[:max_batch_scenarios] >= 3
      it_behaves_like 'parent node with three batches of children'
    end
    
    if record_config[:max_batch_scenarios] >= 4
      it_behaves_like 'parent node with four batches of children'
      it_behaves_like 'parent node lazy loading behavior'
    end
  end

  context 'leaf node' do
    it_behaves_like 'leaf node behavior'
  end

  describe 'columns' do
    if record_config[:columns][:conditional]
      it_behaves_like 'column rendering with conditionals'
    else
      it_behaves_like 'simple column rendering'
    end
  end

  if record_config[:supports_suppression]
    describe 'suppressed badge' do
      it_behaves_like 'suppressed badge behavior'
    end
  end

  if record_config[:supports_mixed_content]
    describe 'mixed content in title column' do
      it_behaves_like 'mixed content behavior'
    end
  end
end


RSpec.shared_examples 'root node with no children' do
  describe 'with no children' do
    let(:child_record) { nil }
    let(:root_record) { create(root_factory, { title: "#{record_type.humanize} #{unique_id}" }.merge(additional_root_attrs)) }
    let(:node) { tree.find("##{record_type}_#{root_record.id}") }
    let(:expected_uri) { root_record.uri }

    let(:tree) do
      visit show_path.call(root_record.id)
      wait_for_ajax
      find('.infinite-tree')
    end

    include_examples 'basic node markup'
    it_behaves_like 'node has no children'
  end
end

RSpec.shared_examples 'root node with one child' do
  describe 'with one child' do
    let(:root_record) { create(root_factory, { title: "#{record_type.humanize} #{unique_id}" }.merge(additional_root_attrs)) }
    let(:child_record) do
      create(child_factory, {
        root_relationship_key => { 'ref' => root_record.uri },
        title: "#{child_type.humanize} #{unique_id}"
      }.merge(additional_child_attrs))
    end
    let(:node) { tree.find("##{record_type}_#{root_record.id}") }
    let(:expected_uri) { root_record.uri }
    let(:total_batches) { 1 }
    let(:child_count) { 1 }

    let(:tree) do
      child_record # Ensure child exists
      visit show_path.call(root_record.id)
      wait_for_ajax
      find('.infinite-tree')
    end

    include_examples 'basic node markup'
    it_behaves_like 'node has correct data-total-child-batches attribute'
    it_behaves_like 'node has X children visible'
  end
end

RSpec.shared_examples 'root node with ten children' do
  describe 'with ten children' do
    total_child_count = 10
    let(:root_record) { create(root_factory, { title: "#{record_type.humanize} #{unique_id}" }.merge(additional_root_attrs)) }
    let!(:children) do
      (total_child_count - 1).times.map do |i|
        create(child_factory, {
          root_relationship_key => { 'ref' => root_record.uri },
          title: "#{child_type.humanize.upcase} #{i + 1} #{unique_id}"
        }.merge(additional_child_attrs.except(:identifier)))
      end
    end
    let(:child_record) do
      create(child_factory, {
        root_relationship_key => { 'ref' => root_record.uri },
        title: "#{child_type.humanize} #{unique_id}"
      }.merge(additional_child_attrs))
    end
    let(:node) { tree.find("##{record_type}_#{root_record.id}") }
    let(:expected_uri) { root_record.uri }
    let(:total_batches) { 1 }
    let(:child_count) { total_child_count }

    let(:tree) do
      child_record # Ensure original child exists
      visit show_path.call(root_record.id)
      wait_for_ajax
      find('.infinite-tree')
    end

    include_examples 'basic node markup'
    it_behaves_like 'node has correct data-total-child-batches attribute'
    it_behaves_like 'node has X children visible'
  end
end

RSpec.shared_examples 'root node with two batches of children' do
  describe 'with two batches of children' do
    let(:total_child_count) { Rails.configuration.infinite_tree_batch_size + 1 }
    child_count_before_lazy_loading_batches = Rails.configuration.infinite_tree_batch_size
    let(:root_record) { create(root_factory, { title: "#{record_type.humanize} #{unique_id}" }.merge(additional_root_attrs)) }
    let!(:children) do
      (total_child_count - 1).times.map do |i|
        create(child_factory, {
          root_relationship_key => { 'ref' => root_record.uri },
          title: "#{child_type.humanize.upcase} #{i + 1} #{unique_id}"
        }.merge(additional_child_attrs.except(:identifier)))
      end
    end
    let(:child_record) do
      create(child_factory, {
        root_relationship_key => { 'ref' => root_record.uri },
        title: "#{child_type.humanize} #{unique_id}"
      }.merge(additional_child_attrs))
    end
    let(:node) { tree.find("##{record_type}_#{root_record.id}") }
    let(:expected_uri) { root_record.uri }
    let(:child_list) { node.find(':scope > .node-children') }
    let(:total_batches) { 2 }
    let(:child_count) { child_count_before_lazy_loading_batches }
    let(:batches_not_yet_loaded) { [1] }

    let(:tree) do
      child_record # Ensure original child exists
      visit show_path.call(root_record.id)
      wait_for_ajax
      find('.infinite-tree')
    end

    include_examples 'basic node markup'
    it_behaves_like 'node has correct data-total-child-batches attribute'
    it_behaves_like 'node has X children visible'
    it_behaves_like 'child list has an observer node for the second batch'
    it_behaves_like 'child list has the correct number of batch placeholders'
    it_behaves_like 'child list lazy loads the remaining batches of children on scroll'
  end
end

RSpec.shared_examples 'root node with three batches of children' do
  describe 'with three batches of children' do
    let(:total_child_count) { Rails.configuration.infinite_tree_batch_size * 2 + 1 }
    child_count_before_lazy_loading_batches = Rails.configuration.infinite_tree_batch_size
    let(:root_record) { create(root_factory, { title: "#{record_type.humanize} #{unique_id}" }.merge(additional_root_attrs)) }
    let!(:children) do
      (total_child_count - 1).times.map do |i|
        create(child_factory, {
          root_relationship_key => { 'ref' => root_record.uri },
          title: "#{child_type.humanize.upcase} #{i + 1} #{unique_id}"
        }.merge(additional_child_attrs.except(:identifier)))
      end
    end
    let(:child_record) do
      create(child_factory, {
        root_relationship_key => { 'ref' => root_record.uri },
        title: "#{child_type.humanize} #{unique_id}"
      }.merge(additional_child_attrs))
    end
    let(:node) { tree.find("##{record_type}_#{root_record.id}") }
    let(:expected_uri) { root_record.uri }
    let(:child_list) { node.find(':scope > .node-children') }
    let(:total_batches) { 3 }
    let(:child_count) { child_count_before_lazy_loading_batches }
    let(:batches_not_yet_loaded) { [1, 2] }

    let(:tree) do
      child_record # Ensure original child exists
      visit show_path.call(root_record.id)
      wait_for_ajax
      find('.infinite-tree')
    end

    include_examples 'basic node markup'
    it_behaves_like 'node has correct data-total-child-batches attribute'
    it_behaves_like 'node has X children visible'
    it_behaves_like 'child list has an observer node for the second batch'
    it_behaves_like 'child list has the correct number of batch placeholders'
    it_behaves_like 'child list lazy loads the remaining batches of children on scroll'
  end
end

RSpec.shared_examples 'root node with four batches of children' do
  describe 'with four batches of children' do
    let(:total_child_count) { Rails.configuration.infinite_tree_batch_size * 3 + 1 }
    child_count_before_lazy_loading_batches = Rails.configuration.infinite_tree_batch_size
    let(:root_record) { create(root_factory, { title: "#{record_type.humanize} #{unique_id}" }.merge(additional_root_attrs)) }
    let!(:children) do
      (total_child_count - 1).times.map do |i|
        create(child_factory, {
          root_relationship_key => { 'ref' => root_record.uri },
          title: "#{child_type.humanize.upcase} #{i + 1} #{unique_id}"
        }.merge(additional_child_attrs.except(:identifier)))
      end
    end
    let(:child_record) do
      create(child_factory, {
        root_relationship_key => { 'ref' => root_record.uri },
        title: "#{child_type.humanize} #{unique_id}"
      }.merge(additional_child_attrs))
    end
    let(:node) { tree.find("##{record_type}_#{root_record.id}") }
    let(:expected_uri) { root_record.uri }
    let(:child_list) { node.find(':scope > .node-children') }
    let(:total_batches) { 4 }
    let(:child_count) { child_count_before_lazy_loading_batches }
    let(:batches_not_yet_loaded) { [1, 2, 3] }

    let(:tree) do
      child_record # Ensure original child exists
      visit show_path.call(root_record.id)
      wait_for_ajax
      find('.infinite-tree')
    end

    include_examples 'basic node markup'
    it_behaves_like 'node has correct data-total-child-batches attribute'
    it_behaves_like 'node has X children visible'
    it_behaves_like 'child list has an observer node for the second batch'
    it_behaves_like 'child list has the correct number of batch placeholders'
    it_behaves_like 'child list lazy loads the remaining batches of children on scroll'
  end
end

RSpec.shared_examples 'parent node with one child' do
  describe 'with one child' do
    total_child_count = 1
    child_count_on_expand = total_child_count
    let(:root_record) { create(root_factory, { title: "#{record_type.humanize} #{unique_id}" }.merge(additional_root_attrs)) }
    let(:parent_record) do
      create(child_factory, {
        root_relationship_key => { 'ref' => root_record.uri },
        title: "#{child_type.humanize} #{unique_id}"
      }.merge(additional_child_attrs))
    end
    let!(:child) do
      create(child_factory, {
        root_relationship_key => { 'ref' => root_record.uri },
        parent: { 'ref' => parent_record.uri },
        title: "Child of #{child_type.humanize} #{unique_id}"
      }.merge(additional_child_attrs))
    end
    let(:node) { tree.find("##{child_type}_#{parent_record.id}") }
    let(:expected_uri) { parent_record.uri }
    let(:total_batches) { 1 }
    let(:child_count) { child_count_on_expand }

    let(:tree) do
      visit show_path.call(root_record.id)
      wait_for_ajax
      find('.infinite-tree')
    end

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
end

RSpec.shared_examples 'parent node with ten children' do
  describe 'with ten children' do
    total_child_count = 10
    child_count_on_expand = total_child_count
    let(:root_record) { create(root_factory, { title: "#{record_type.humanize} #{unique_id}" }.merge(additional_root_attrs)) }
    let(:parent_record) do
      create(child_factory, {
        root_relationship_key => { 'ref' => root_record.uri },
        title: "#{child_type.humanize} #{unique_id}"
      }.merge(additional_child_attrs))
    end
    let!(:children) do
      total_child_count.times.map do |i|
        create(child_factory, {
          root_relationship_key => { 'ref' => root_record.uri },
          parent: { 'ref' => parent_record.uri },
          title: "Child #{i + 1} of #{child_type.humanize} #{unique_id}"
        }.merge(additional_child_attrs.except(:identifier)))
      end
    end
    let(:node) { tree.find("##{child_type}_#{parent_record.id}") }
    let(:expected_uri) { parent_record.uri }
    let(:total_batches) { 1 }
    let(:child_count) { child_count_on_expand }

    let(:tree) do
      visit show_path.call(root_record.id)
      wait_for_ajax
      find('.infinite-tree')
    end

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
end

RSpec.shared_examples 'parent node with two batches of children' do
  describe 'with two batches of children' do
    let(:total_child_count) { Rails.configuration.infinite_tree_batch_size + 1 }
    child_count_on_expand_before_lazy_loading_batches = Rails.configuration.infinite_tree_batch_size
    let(:root_record) { create(root_factory, { title: "#{record_type.humanize} #{unique_id}" }.merge(additional_root_attrs)) }
    let(:parent_record) do
      create(child_factory, {
        root_relationship_key => { 'ref' => root_record.uri },
        title: "#{child_type.humanize} #{unique_id}"
      }.merge(additional_child_attrs))
    end
    let!(:children) do
      total_child_count.times.map do |i|
        create(child_factory, {
          root_relationship_key => { 'ref' => root_record.uri },
          parent: { 'ref' => parent_record.uri },
          title: "Child #{i + 1} of #{child_type.humanize} #{unique_id}"
        }.merge(additional_child_attrs.except(:identifier)))
      end
    end
    let(:node) { tree.find("##{child_type}_#{parent_record.id}") }
    let(:expected_uri) { parent_record.uri }
    let(:total_batches) { 2 }
    let(:child_count) { child_count_on_expand_before_lazy_loading_batches }

    let(:tree) do
      visit show_path.call(root_record.id)
      wait_for_ajax
      find('.infinite-tree')
    end

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

RSpec.shared_examples 'parent node with three batches of children' do
  describe 'with three batches of children' do
    let(:total_child_count) { Rails.configuration.infinite_tree_batch_size * 2 + 1 }
    child_count_on_expand_before_lazy_loading_batches = Rails.configuration.infinite_tree_batch_size
    let(:root_record) { create(root_factory, { title: "#{record_type.humanize} #{unique_id}" }.merge(additional_root_attrs)) }
    let(:parent_record) do
      create(child_factory, {
        root_relationship_key => { 'ref' => root_record.uri },
        title: "#{child_type.humanize} #{unique_id}"
      }.merge(additional_child_attrs))
    end
    let!(:children) do
      total_child_count.times.map do |i|
        create(child_factory, {
          root_relationship_key => { 'ref' => root_record.uri },
          parent: { 'ref' => parent_record.uri },
          title: "Child #{i + 1} of #{child_type.humanize} #{unique_id}"
        }.merge(additional_child_attrs.except(:identifier)))
      end
    end
    let(:node) { tree.find("##{child_type}_#{parent_record.id}") }
    let(:expected_uri) { parent_record.uri }
    let(:total_batches) { 3 }
    let(:child_count) { child_count_on_expand_before_lazy_loading_batches }

    let(:tree) do
      visit show_path.call(root_record.id)
      wait_for_ajax
      find('.infinite-tree')
    end

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
end

RSpec.shared_examples 'parent node with four batches of children' do
  describe 'with four batches of children' do
    let(:total_child_count) { Rails.configuration.infinite_tree_batch_size * 3 + 1 }
    child_count_on_expand_before_lazy_loading_batches = Rails.configuration.infinite_tree_batch_size
    let(:root_record) { create(root_factory, { title: "#{record_type.humanize} #{unique_id}" }.merge(additional_root_attrs)) }
    let(:parent_record) do
      create(child_factory, {
        root_relationship_key => { 'ref' => root_record.uri },
        title: "#{child_type.humanize} #{unique_id}"
      }.merge(additional_child_attrs))
    end
    let!(:children) do
      total_child_count.times.map do |i|
        create(child_factory, {
          root_relationship_key => { 'ref' => root_record.uri },
          parent: { 'ref' => parent_record.uri },
          title: "Child #{i + 1} of #{child_type.humanize} #{unique_id}"
        }.merge(additional_child_attrs.except(:identifier)))
      end
    end
    let(:node) { tree.find("##{child_type}_#{parent_record.id}") }
    let(:expected_uri) { parent_record.uri }
    let(:total_batches) { 4 }
    let(:child_count) { child_count_on_expand_before_lazy_loading_batches }

    let(:tree) do
      visit show_path.call(root_record.id)
      wait_for_ajax
      find('.infinite-tree')
    end

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
end

RSpec.shared_examples 'parent node lazy loading behavior' do
  context 'after batches are lazy loaded' do
    let(:total_child_count) { Rails.configuration.infinite_tree_batch_size * 3 + 1 }
    let(:root_record) { create(root_factory, { title: "#{record_type.humanize} #{unique_id}" }.merge(additional_root_attrs)) }
    let(:parent_record) do
      create(child_factory, {
        root_relationship_key => { 'ref' => root_record.uri },
        title: "#{child_type.humanize} #{unique_id}"
      }.merge(additional_child_attrs))
    end
    let!(:children) do
      total_child_count.times.map do |i|
        create(child_factory, {
          root_relationship_key => { 'ref' => root_record.uri },
          parent: { 'ref' => parent_record.uri },
          title: "Child #{i + 1} of #{child_type.humanize} #{unique_id}"
        }.merge(additional_child_attrs.except(:identifier)))
      end
    end
    let(:node) { tree.find("##{child_type}_#{parent_record.id}") }

    let(:tree) do
      visit show_path.call(root_record.id)
      wait_for_ajax
      find('.infinite-tree')
    end

    before(:each) do
      node.find(':scope > .node-row .node-expand').click
      wait_for_ajax
    end

    let(:child_list) { node.find(':scope > .node-children') }
    let(:child_count_on_initial_expand) { Rails.configuration.infinite_tree_batch_size }
    let(:batches_to_load) { [1, 2, 3] }

    it_behaves_like 'collapsing hides all previously loaded children'
    it_behaves_like 'expanding shows all previously loaded children'
  end
end

RSpec.shared_examples 'leaf node behavior' do
  let(:root_record) { create(root_factory, { title: "#{record_type.humanize} #{unique_id}" }.merge(additional_root_attrs)) }
  let(:leaf_record) do
    create(child_factory, {
      root_relationship_key => { 'ref' => root_record.uri },
      title: "#{child_type.humanize} #{unique_id}"
    }.merge(additional_child_attrs))
  end
  let(:node) { tree.find("##{child_type}_#{leaf_record.id}") }
  let(:expected_uri) { leaf_record.uri }

  let(:tree) do
    leaf_record # Ensure record exists
    visit show_path.call(root_record.id)
    wait_for_ajax
    find('.infinite-tree')
  end

  include_examples 'basic node markup'
  it_behaves_like 'node has no children'
end

RSpec.shared_examples 'simple column rendering' do
  let(:root_record) { create(root_factory, { title: "#{record_type.humanize} #{unique_id}" }.merge(additional_root_attrs)) }
  let(:child_record) do
    create(child_factory, {
      root_relationship_key => { 'ref' => root_record.uri },
      title: "#{child_type.humanize} #{unique_id}"
    }.merge(additional_child_attrs))
  end

  let(:tree) do
    child_record # Ensure record exists
    visit show_path.call(root_record.id)
    wait_for_ajax
    find('.infinite-tree')
  end

  it_behaves_like 'renders base columns'
end

RSpec.shared_examples 'column rendering with conditionals' do
  let(:root_record) { create(root_factory, { title: "#{record_type.humanize} #{unique_id}" }.merge(additional_root_attrs)) }
  let(:child_record) do
    create(child_factory, {
      root_relationship_key => { 'ref' => root_record.uri },
      title: "#{child_type.humanize} #{unique_id}"
    }.merge(additional_child_attrs))
  end

  let(:tree) do
    child_record # Ensure record exists
    visit show_path.call(root_record.id)
    wait_for_ajax
    find('.infinite-tree')
  end

  it_behaves_like 'renders base columns'
  it_behaves_like 'shows conditional columns when enabled'
  it_behaves_like 'hides conditional columns when disabled'
end

RSpec.shared_examples 'renders base columns' do
  it 'renders the base columns' do
    if columns_config && columns_config[:base]
      aggregate_failures do
        columns_config[:base].each do |column|
          expect(tree).to have_css("[data-column=\"#{column}\"]", visible: :all)
        end
      end
    end
  end
end

RSpec.shared_examples 'shows conditional columns when enabled' do
  before(:each) do
    allow(AppConfig).to receive(:[]).and_call_original
    columns_config[:conditional].each do |column_name, config_key|
      allow(AppConfig).to receive(:[])
        .with(config_key.to_sym)
        .and_return(true)
    end
  end

  it 'shows conditional columns when enabled' do
    aggregate_failures do
      columns_config[:conditional].each do |column_name, config_key|
        expect(tree).to have_css("[data-column=\"#{column_name}\"]", visible: :all)
      end
    end
  end
end

RSpec.shared_examples 'hides conditional columns when disabled' do
  before(:each) do
    allow(AppConfig).to receive(:[]).and_call_original
    columns_config[:conditional].each do |column_name, config_key|
      allow(AppConfig).to receive(:[])
        .with(config_key.to_sym)
        .and_return(false)
    end
  end

  it 'hides conditional columns when disabled' do
    aggregate_failures do
      columns_config[:conditional].each do |column_name, config_key|
        expect(tree).not_to have_css("[data-column=\"#{column_name}\"]", visible: :all)
      end
    end
  end
end

RSpec.shared_examples 'suppressed badge behavior' do
  let(:root_record) { create(root_factory, { title: "#{record_type.humanize} #{unique_id}" }.merge(additional_root_attrs)) }
  let!(:suppressed_record) do
    create(child_factory, {
      root_relationship_key => { 'ref' => root_record.uri },
      title: "Suppressed #{child_type.humanize} #{unique_id}"
    }.merge(additional_child_attrs)).tap { |obj| obj.set_suppressed(true) }
  end

  let(:tree) do
    visit show_path.call(root_record.id)
    wait_for_ajax
    find('.infinite-tree')
  end

  it 'is shown only for suppressed records' do
    tree # Ensure tree is loaded
    badge_selector = '#infinite-tree-container .record-title .badge'
    badge = find(badge_selector, text: 'Suppressed', match: :first)
    badge_parent = badge.find(:xpath, '..')

    expect(page).to have_css(badge_selector, text: 'Suppressed', count: 1)
    expect(badge_parent['title']).to eq(suppressed_record.title)
  end
end

RSpec.shared_examples 'mixed content behavior' do
  let(:root_record) do
    create(root_factory, {
      title: 'This is <emph>a mixed content</emph> title'
    }.merge(additional_root_attrs))
  end

  let!(:mixed_content_child) do
    create(child_factory, {
      root_relationship_key => { 'ref' => root_record.uri },
      title: 'This is <emph render="italic">another mixed content</emph> title'
    }.merge(additional_child_attrs))
  end

  let!(:plain_child) do
    create(child_factory, {
      root_relationship_key => { 'ref' => root_record.uri },
      title: 'This is not a mixed content title'
    }.merge(additional_child_attrs))
  end

  let(:allow_mixed_content_title_fields) { true }

  before(:each) do
    allow(AppConfig).to receive(:[]).and_call_original
    allow(AppConfig)
      .to receive(:[])
      .with(:allow_mixed_content_title_fields)
      .and_return(allow_mixed_content_title_fields)
  end

  let(:tree) do
    visit show_path.call(root_record.id)
    wait_for_ajax
    find('.infinite-tree')
  end

  it 'renders titles with mixed content appropriately' do
    tree # Ensure tree is loaded

    root_node = find("##{record_type}_#{root_record.id}")
    expect(root_node).to have_css('.node-body[title="This is a mixed content title"]')
    root_mixed_span = root_node.find('.node-row span.emph.render-none')
    expect(root_mixed_span).to have_text('a mixed content')

    mixed_child_node = find("##{child_type}_#{mixed_content_child.id}")
    expect(mixed_child_node).to have_css('.node-row > .node-body[title="This is another mixed content title"]')
    mixed_child_span = mixed_child_node.find('.node-row span.emph.render-italic')
    expect(mixed_child_span).to have_text('another mixed content')

    plain_child_node = find("##{child_type}_#{plain_child.id}")
    plain_title = plain_child_node.find('.node-row .record-title')
    expect(plain_title).not_to have_css('span')
    expect(plain_title).to have_text('This is not a mixed content title')
  end
end
