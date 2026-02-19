# Shared examples for Infinite Tree functionality across record types

RSpec.shared_examples 'infinite tree record show view' do |record_config|
  let(:record_type) { record_config[:record_type] }
  let(:child_type) { record_config[:child_type] }
  let(:root_factory) { record_config[:root_factory] }
  let(:child_factory) { record_config[:child_factory] }
  let(:root_relationship_key) { record_config[:root_relationship_key] }
  let(:show_path) { record_config[:show_path] }
  let(:columns_config) { record_config[:columns] }
  let(:max_batch_scenarios) { record_config[:max_batch_scenarios] || 4 }

  before(:all) do
    now = Time.now.to_i
    @test_prefix = "#{record_config[:record_type]}_#{now}"
    @batch_size = Rails.configuration.infinite_tree_batch_size
    @repo = create(:repo, repo_code: "infinite_tree_test_#{@test_prefix}")
    set_repo(@repo)

    # Evaluate additional attrs for this record type
    root_attrs_proc = record_config[:additional_root_attrs]
    child_attrs_proc = record_config[:additional_child_attrs]
    @additional_root_attrs = root_attrs_proc.respond_to?(:call) ? root_attrs_proc.call(@test_prefix) : (root_attrs_proc || {})
    @additional_child_attrs = child_attrs_proc.respond_to?(:call) ? child_attrs_proc.call(@test_prefix) : (child_attrs_proc || {})

    create_root_node_test_data(record_config)
    create_parent_node_test_data(record_config)
    create_misc_test_data(record_config)
  end

  before(:each) do
    unless page.has_css?('.nav-link', text: 'admin', wait: 0)
      login_admin
    end

    unless page.has_css?('.repository-badge', text: @repo.repo_code, wait: 0)
      select_repository(@repo)
    end
  end

  let(:container) { find('#infinite-tree-container') }
  let(:basic_root_record) { @basic_root_record }
  let(:basic_child_record) { @basic_child_record }
  subject(:tree) do
    visit show_path.call(basic_root_record.id)
    wait_for_ajax
    find('.infinite-tree')
  end

  private

  def create_root_node_test_data(config)
    factory = config[:root_factory]
    child_factory = config[:child_factory]
    relationship_key = config[:root_relationship_key]

    @root_no_children = create(factory, { title: "Root no children #{@test_prefix}" }.merge(@additional_root_attrs))

    @root_three_children = create(factory, { title: "Root three children #{@test_prefix}" }.merge(@additional_root_attrs))
    @root_three_children_children = 3.times.map do |i|
      create(child_factory, {
        relationship_key => { 'ref' => @root_three_children.uri },
        title: "Child #{i + 1} of root three children #{@test_prefix}"
      }.merge(@additional_child_attrs.except(:identifier)))
    end

    @root_two_batches = create(factory, { title: "Root two batches #{@test_prefix}" }.merge(@additional_root_attrs))
    two_batch_count = @batch_size + 1
    @root_two_batches_children = two_batch_count.times.map do |i|
      create(child_factory, {
        relationship_key => { 'ref' => @root_two_batches.uri },
        title: "Child #{i + 1} of root two batches #{@test_prefix}"
      }.merge(@additional_child_attrs.except(:identifier)))
    end

    if config[:max_batch_scenarios] >= 3
      @root_three_batches = create(factory, { title: "Root three batches #{@test_prefix}" }.merge(@additional_root_attrs))
      three_batch_count = @batch_size * 2 + 1
      @root_three_batches_children = three_batch_count.times.map do |i|
        create(child_factory, {
          relationship_key => { 'ref' => @root_three_batches.uri },
          title: "Child #{i + 1} of root three batches #{@test_prefix}"
        }.merge(@additional_child_attrs.except(:identifier)))
      end
    end

    if config[:max_batch_scenarios] >= 4
      @root_four_batches = create(factory, { title: "Root four batches #{@test_prefix}" }.merge(@additional_root_attrs))
      four_batch_count = @batch_size * 3 + 1
      @root_four_batches_children = four_batch_count.times.map do |i|
        create(child_factory, {
          relationship_key => { 'ref' => @root_four_batches.uri },
          title: "Child #{i + 1} of root four batches #{@test_prefix}"
        }.merge(@additional_child_attrs.except(:identifier)))
      end
    end

    @basic_root_record = create(factory, { title: "Basic root #{@test_prefix}" }.merge(@additional_root_attrs))
    @basic_child_record = create(child_factory, {
      relationship_key => { 'ref' => @basic_root_record.uri },
      title: "Basic child #{@test_prefix}"
    }.merge(@additional_child_attrs))
  end

  def create_parent_node_test_data(config)
    factory = config[:root_factory]
    child_factory = config[:child_factory]
    relationship_key = config[:root_relationship_key]

    @parent_three_children_root = create(factory, { title: "Parent three children root #{@test_prefix}" }.merge(@additional_root_attrs))
    @parent_three_children = create(child_factory, {
      relationship_key => { 'ref' => @parent_three_children_root.uri },
      title: "Parent three children #{@test_prefix}"
    }.merge(@additional_child_attrs))
    @parent_three_children_children = 3.times.map do |i|
      create(child_factory, {
        relationship_key => { 'ref' => @parent_three_children_root.uri },
        parent: { 'ref' => @parent_three_children.uri },
        title: "Child #{i + 1} of parent three children #{@test_prefix}"
      }.merge(@additional_child_attrs.except(:identifier)))
    end

    @parent_two_batches_root = create(factory, { title: "Parent two batches root #{@test_prefix}" }.merge(@additional_root_attrs))
    @parent_two_batches = create(child_factory, {
      relationship_key => { 'ref' => @parent_two_batches_root.uri },
      title: "Parent two batches #{@test_prefix}"
    }.merge(@additional_child_attrs))
    two_batch_count = @batch_size + 1
    @parent_two_batches_children = two_batch_count.times.map do |i|
      create(child_factory, {
        relationship_key => { 'ref' => @parent_two_batches_root.uri },
        parent: { 'ref' => @parent_two_batches.uri },
        title: "Child #{i + 1} of parent two batches #{@test_prefix}"
      }.merge(@additional_child_attrs.except(:identifier)))
    end

    if config[:max_batch_scenarios] >= 3
      @parent_three_batches_root = create(factory, { title: "Parent three batches root #{@test_prefix}" }.merge(@additional_root_attrs))
      @parent_three_batches = create(child_factory, {
        relationship_key => { 'ref' => @parent_three_batches_root.uri },
        title: "Parent three batches #{@test_prefix}"
      }.merge(@additional_child_attrs))
      three_batch_count = @batch_size * 2 + 1
      @parent_three_batches_children = three_batch_count.times.map do |i|
        create(child_factory, {
          relationship_key => { 'ref' => @parent_three_batches_root.uri },
          parent: { 'ref' => @parent_three_batches.uri },
          title: "Child #{i + 1} of parent three batches #{@test_prefix}"
        }.merge(@additional_child_attrs.except(:identifier)))
      end
    end

    if config[:max_batch_scenarios] >= 4
      @parent_four_batches_root = create(factory, { title: "Parent four batches root #{@test_prefix}" }.merge(@additional_root_attrs))
      @parent_four_batches = create(child_factory, {
        relationship_key => { 'ref' => @parent_four_batches_root.uri },
        title: "Parent four batches #{@test_prefix}"
      }.merge(@additional_child_attrs))
      four_batch_count = @batch_size * 3 + 1
      @parent_four_batches_children = four_batch_count.times.map do |i|
        create(child_factory, {
          relationship_key => { 'ref' => @parent_four_batches_root.uri },
          parent: { 'ref' => @parent_four_batches.uri },
          title: "Child #{i + 1} of parent four batches #{@test_prefix}"
        }.merge(@additional_child_attrs.except(:identifier)))
      end

      @lazy_loading_root = @parent_four_batches_root
      @lazy_loading_parent = @parent_four_batches
      @lazy_loading_children = @parent_four_batches_children
    end
  end

  def create_misc_test_data(config)
    factory = config[:root_factory]
    child_factory = config[:child_factory]
    relationship_key = config[:root_relationship_key]

    @leaf_root = create(factory, { title: "Leaf root #{@test_prefix}" }.merge(@additional_root_attrs))
    @leaf_record = create(child_factory, {
      relationship_key => { 'ref' => @leaf_root.uri },
      title: "Leaf record #{@test_prefix}"
    }.merge(@additional_child_attrs))

    @columns_root = create(factory, { title: "Columns root #{@test_prefix}" }.merge(@additional_root_attrs))
    @columns_child = create(child_factory, {
      relationship_key => { 'ref' => @columns_root.uri },
      title: "Columns child #{@test_prefix}"
    }.merge(@additional_child_attrs))

    if config[:supports_suppression]
      @suppressed_root = create(factory, { title: "Suppressed root #{@test_prefix}" }.merge(@additional_root_attrs))
      @suppressed_child = create(child_factory, {
        relationship_key => { 'ref' => @suppressed_root.uri },
        title: "Suppressed child #{@test_prefix}"
      }.merge(@additional_child_attrs))
      @suppressed_child.set_suppressed(true)
    end

    if config[:supports_mixed_content]
      @mixed_content_root = create(factory, {
        title: 'This is <emph>a mixed content</emph> title'
      }.merge(@additional_root_attrs))
      @mixed_content_child = create(child_factory, {
        relationship_key => { 'ref' => @mixed_content_root.uri },
        title: 'This is <emph render="italic">another mixed content</emph> title'
      }.merge(@additional_child_attrs))
      @plain_content_child = create(child_factory, {
        relationship_key => { 'ref' => @mixed_content_root.uri },
        title: 'This is not a mixed content title'
      }.merge(@additional_child_attrs))
    end
  end

  describe 'tree list' do
    it 'has the correct role and child item' do
      aggregate_failures do
        expect(tree['role']).to eq('tree')
        expect(tree).to have_css(':scope > li', count: 1)
        expect(tree).to have_css(':scope > li.root.node')
      end
    end
  end

  context 'root node' do
    it_behaves_like 'root node with no children'
    it_behaves_like 'root node with three children'
    it_behaves_like 'root node with N batches of children', 2

    if record_config[:max_batch_scenarios] >= 3
      it_behaves_like 'root node with N batches of children', 3
    end

    if record_config[:max_batch_scenarios] >= 4
      it_behaves_like 'root node with N batches of children', 4
    end
  end

  context 'parent node' do
    it_behaves_like 'parent node with three children'
    it_behaves_like 'parent node with N batches of children', 2

    if record_config[:max_batch_scenarios] >= 3
      it_behaves_like 'parent node with N batches of children', 3
    end

    if record_config[:max_batch_scenarios] >= 4
      it_behaves_like 'parent node with N batches of children', 4
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
    let(:root_record) { @root_no_children }
    let(:node) { tree.find("##{record_type}_#{root_record.id}") }
    let(:expected_uri) { root_record.uri }
    let(:tree) do
      visit show_path.call(root_record.id)
      wait_for_ajax
      find('.infinite-tree')
    end

    it_behaves_like 'basic node markup'
    it_behaves_like 'node has no children'
  end
end

RSpec.shared_examples 'root node with three children' do
  describe 'with three children' do
    let(:root_record) { @root_three_children }
    let(:children) { @root_three_children_children }
    let(:node) { tree.find("##{record_type}_#{root_record.id}") }
    let(:expected_uri) { root_record.uri }
    let(:total_batches) { 1 }
    let(:child_count) { 3 }
    let(:tree) do
      visit show_path.call(root_record.id)
      wait_for_ajax
      find('.infinite-tree')
    end

    it_behaves_like 'basic node markup'
    it_behaves_like 'node has correct data-total-child-batches attribute'
    it_behaves_like 'node has X children visible'
  end
end

RSpec.shared_examples 'root node with N batches of children' do |batch_count|
  describe "with #{batch_count} batches of children" do
    let(:root_record) do
      case batch_count
      when 2 then @root_two_batches
      when 3 then @root_three_batches
      when 4 then @root_four_batches
      end
    end
    let(:children) do
      case batch_count
      when 2 then @root_two_batches_children
      when 3 then @root_three_batches_children
      when 4 then @root_four_batches_children
      end
    end
    let(:total_child_count) { @batch_size * (batch_count - 1) + 1 }
    let(:node) { tree.find("##{record_type}_#{root_record.id}") }
    let(:expected_uri) { root_record.uri }
    let(:child_list) { node.find(':scope > .node-children') }
    let(:total_batches) { batch_count }
    let(:child_count) { @batch_size }
    let(:batches_not_yet_loaded) { (1...batch_count).to_a }
    let(:tree) do
      visit show_path.call(root_record.id)
      wait_for_ajax
      find('.infinite-tree')
    end

    it_behaves_like 'basic node markup'
    it_behaves_like 'node has correct data-total-child-batches attribute'
    it_behaves_like 'node has X children visible'
    it_behaves_like 'child list has an observer node for the second batch'
    it_behaves_like 'child list has the correct number of batch placeholders'
    it_behaves_like 'child list lazy loads the remaining batches of children on scroll'
  end
end

RSpec.shared_examples 'parent node with three children' do
  describe 'with three children' do
    let(:root_record) { @parent_three_children_root }
    let(:parent_record) { @parent_three_children }
    let(:children) { @parent_three_children_children }
    let(:node) { tree.find("##{child_type}_#{parent_record.id}") }
    let(:expected_uri) { parent_record.uri }
    let(:total_batches) { 1 }
    let(:child_count) { 3 }
    let(:tree) do
      visit show_path.call(root_record.id)
      wait_for_ajax
      find('.infinite-tree')
    end

    it_behaves_like 'basic node markup'
    it_behaves_like 'node has correct data-total-child-batches attribute'
    it_behaves_like 'parent node has not been expanded'
    it_behaves_like 'parent node expand and collapse behavior'
  end
end

RSpec.shared_examples 'parent node with N batches of children' do |batch_count|
  describe "with #{batch_count} batches of children" do
    let(:root_record) do
      case batch_count
      when 2 then @parent_two_batches_root
      when 3 then @parent_three_batches_root
      when 4 then @parent_four_batches_root
      end
    end
    let(:parent_record) do
      case batch_count
      when 2 then @parent_two_batches
      when 3 then @parent_three_batches
      when 4 then @parent_four_batches
      end
    end
    let(:children) do
      case batch_count
      when 2 then @parent_two_batches_children
      when 3 then @parent_three_batches_children
      when 4 then @parent_four_batches_children
      end
    end
    let(:total_child_count) { @batch_size * (batch_count - 1) + 1 }
    let(:node) { tree.find("##{child_type}_#{parent_record.id}") }
    let(:expected_uri) { parent_record.uri }
    let(:total_batches) { batch_count }
    let(:child_count) { @batch_size }
    let(:tree) do
      visit show_path.call(root_record.id)
      wait_for_ajax
      find('.infinite-tree')
    end

    it_behaves_like 'basic node markup'
    it_behaves_like 'node has correct data-total-child-batches attribute'
    it_behaves_like 'parent node has not been expanded'
    it_behaves_like 'parent node expand and collapse behavior'

    describe 'after initial expansion' do
      before do
        node.find(':scope > .node-row .node-expand').click
        wait_for_ajax
      end

      let(:child_list) { node.find(':scope > .node-children') }
      let(:batches_not_yet_loaded) { (1...batch_count).to_a }

      it_behaves_like 'child list has an observer node for the second batch'
      it_behaves_like 'child list has the correct number of batch placeholders'
      it_behaves_like 'child list lazy loads the remaining batches of children on scroll'
    end
  end
end

RSpec.shared_examples 'parent node lazy loading behavior' do
  context 'after batches are lazy loaded' do
    let(:root_record) { @lazy_loading_root }
    let(:parent_record) { @lazy_loading_parent }
    let(:children) { @lazy_loading_children }
    let(:total_child_count) { @batch_size * 3 + 1 }
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
    let(:child_count_on_initial_expand) { @batch_size }
    let(:batches_to_load) { [1, 2, 3] }

    it_behaves_like 'collapsing hides all previously loaded children'
    it_behaves_like 'expanding shows all previously loaded children'
  end
end

RSpec.shared_examples 'leaf node behavior' do
  let(:root_record) { @leaf_root }
  let(:leaf_record) { @leaf_record }
  let(:node) { tree.find("##{child_type}_#{leaf_record.id}") }
  let(:expected_uri) { leaf_record.uri }
  let(:tree) do
    visit show_path.call(root_record.id)
    wait_for_ajax
    find('.infinite-tree')
  end

  it_behaves_like 'basic node markup'
  it_behaves_like 'node has no children'
end

RSpec.shared_examples 'simple column rendering' do
  let(:root_record) { @columns_root }
  let(:child_record) { @columns_child }
  let(:tree) do
    visit show_path.call(root_record.id)
    wait_for_ajax
    find('.infinite-tree')
  end

  it_behaves_like 'renders base columns'
end

RSpec.shared_examples 'column rendering with conditionals' do
  let(:root_record) { @columns_root }
  let(:child_record) { @columns_child }
  let(:tree) do
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
  let(:root_record) { @suppressed_root }
  let(:suppressed_record) { @suppressed_child }
  let(:tree) do
    visit show_path.call(root_record.id)
    wait_for_ajax
    find('.infinite-tree')
  end

  it 'is shown only for suppressed records' do
    tree
    badge_selector = '#infinite-tree-container .record-title .badge'
    badge = find(badge_selector, text: 'Suppressed', match: :first)
    badge_parent = badge.find(:xpath, '..')

    aggregate_failures do
      expect(page).to have_css(badge_selector, text: 'Suppressed', count: 1)
      expect(badge_parent['title']).to eq(suppressed_record.title)
    end
  end
end

RSpec.shared_examples 'mixed content behavior' do
  let(:root_record) { @mixed_content_root }
  let(:mixed_content_child) { @mixed_content_child }
  let(:plain_child) { @plain_content_child }
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
    tree
    aggregate_failures do
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
end
