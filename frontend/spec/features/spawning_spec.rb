# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Spawning an Archival Object from an Accession', js: true do
  before(:all) do
    @now = Time.now.to_i
    @repo = create(:repo, repo_code: "spawning_test_#{@now}")
    set_repo(@repo)

    @accession = create(
      :json_accession,
      title: "Spawned Accession #{@now}",
      extents: [build(:json_extent)],
      dates: [build(:json_date, date_type: 'single')]
    )

    @resource = create(:resource, title: "Picker Resource #{@now}")
    @first = create_component(@resource, "First #{@now}")
    @parent = create_component(@resource, "Parent #{@now}")
    @nested_first = create_component(@resource, "Nested First #{@now}", parent: @parent)
    @nested_second = create_component(@resource, "Nested Second #{@now}", parent: @parent)
    @last = create_component(@resource, "Last #{@now}")

    @other_resource = create(:resource, title: "Other Resource #{@now}")
    @other_component = create_component(@other_resource, "Other Component #{@now}")

    @empty_resource = create(:resource, title: "Empty Resource #{@now}")

    @nesting_resource = create(:resource, title: "Nesting Resource #{@now}")
    @nesting_parent = create_component(@nesting_resource, "Nesting Parent #{@now}")

    @ordering_resource = create(:resource, title: "Ordering Resource #{@now}")
    @ordering_first = create_component(@ordering_resource, "Ordering First #{@now}")
    @ordering_second = create_component(@ordering_resource, "Ordering Second #{@now}")

    run_all_indexers
  end

  before(:each) do
    login_admin
    select_repository(@repo)
  end

  let(:menu_selector) { '#linkResourceModal ul.infinite-tree-parent-picker__menu[role="menu"]' }
  let(:placeholder_selector) { '#linkResourceModal li.spawn-placeholder' }
  let(:root_list_selector) { '#linkResourceModal li.root.node > ol.node-children' }
  let(:confirm_label) { I18n.t('archival_object._frontend.action.select_parent_and_position') }
  let(:placeholder_text) { I18n.t('archival_object._frontend.messages.spawn_placeholder') }

  it 'creates the component in the chosen position and links it to the accession' do
    visit "/accessions/#{@accession.id}"
    find('#spawn-dropdown > button').click
    within('#spawn-dropdown .dropdown-menu') { click_link I18n.t('archival_object._singular') }
    choose_resource(@nesting_resource)
    wait_for_parent_picker
    choose_placement(@nesting_parent, :child)
    confirm_placement

    aggregate_failures 'the form is prefilled and placed' do
      expect(location_query['resource_id']).to eq(@nesting_resource.id.to_s)
      expect_spawn_placement(parent: @nesting_parent, position: 0)
      expect(find('#archival_object_title_', visible: false).value).to eq(@accession.title)
      expect(
        find("form input[name='archival_object[accession_links][0][ref]']", visible: false).value
      ).to eq(@accession.uri)
    end

    spawned_id = save_spawned_component(@nesting_resource)
    expect(page).to have_css(
      "#infinite-tree-container li##{infinite_tree_node_id_for(@nesting_parent)} > ol.node-children > " \
      "li#archival_object_#{spawned_id}:first-child",
      text: @accession.title
    )

    ref_id = find('.identifier-display').text
    visit "/accessions/#{@accession.id}"
    expect(find('#accession_component_links_ table tbody tr td:nth-child(1)').text).to eq(ref_id)
  end

  describe 'the parent picker' do
    context 'when it opens' do
      before { open_parent_picker(@resource) }

      it 'shows the Resource in a browse-only InfiniteTree' do
        within '#linkResourceModal' do
          aggregate_failures do
            expect(page).to have_css(
              "#infinite-tree-component.infinite-tree-parent-picker[data-root-uri='#{@resource.uri}']"
            )
            expect(page).to have_css(
              'ol.infinite-tree[role="tree"] > li.root.node > .node-row .record-title:not([href])',
              text: @resource.title
            )
            expect(page).to have_css(
              "li##{infinite_tree_node_id_for(@first)} > .node-row a.record-title",
              text: @first.title
            )
            expect(page).to have_no_css('#infinite-tree-record-pane, #infinite-tree-toolbar, [data-resize-handle]')
            expect(page).to have_no_css('.largetree-node, .table-row')
            expect(page).to have_no_css('li.node.spawn-anchor, li.spawn-placeholder', visible: :all)
            expect(page).to have_button(confirm_label, disabled: true)
          end
        end
      end
    end

    describe 'activating a row' do
      before { open_parent_picker(@resource) }

      it 'marks the row as the spawn anchor and opens its placement menu' do
        activate_row(@first)

        aggregate_failures do
          expect(page).to have_css(picker_node_selector(@first, '.spawn-anchor'))
          expect(page).to have_css('#linkResourceModal li.node.spawn-anchor', count: 1)
          expect(page).to have_css("#{menu_selector} [role='menuitem']", count: 3)
          expect(page).to have_css("#{menu_selector} .add-items-before", text: menu_label(:before), focused: true)
          expect(page).to have_css("#{menu_selector} .add-items-as-children", text: menu_label(:child))
          expect(page).to have_css("#{menu_selector} .add-items-after", text: menu_label(:after))
          expect(page).to have_button(confirm_label, disabled: true)
        end
      end

      it 'activates from anywhere on the row' do
        tree_row(@last.uri).find('.node-column[data-column="level"]').click

        aggregate_failures do
          expect(page).to have_css(picker_node_selector(@last, '.spawn-anchor'))
          expect(page).to have_css(menu_selector)
        end
      end

      it 'moves the spawn anchor to a newly activated row' do
        # The menu opens below its anchor, so activate rows upward to avoid flakiness
        activate_row(@last)
        activate_row(@first)

        aggregate_failures do
          expect(page).to have_css('#linkResourceModal li.node.spawn-anchor', count: 1)
          expect(page).to have_css(picker_node_selector(@first, '.spawn-anchor'))
          expect(page).to have_css(menu_selector, count: 1)
        end
      end

      it "doesn't activate when clicking on the root row or any expand button" do
        expand_tree_node(@parent.uri)
        expect(page).to have_css(picker_node_selector(@nested_first))

        find('#linkResourceModal li.root.node > .node-row .record-title').click

        aggregate_failures do
          expect(page).to have_css(picker_node_selector(@parent, "[aria-expanded='true']"))
          expect(page).to have_no_css('#linkResourceModal li.node.spawn-anchor')
          expect(page).to have_no_css(menu_selector)
        end
      end
    end

    describe 'dismissing the placement menu' do
      before { open_parent_picker(@resource) }

      it 'clears the spawn anchor when clicking outside the menu' do
        activate_row(@first)
        find('#linkResourceModal .modal-header').click

        aggregate_failures do
          expect(page).to have_no_css(menu_selector)
          expect(page).to have_no_css(picker_node_selector(@first, '.spawn-anchor'))
        end
      end

      it 'clears the spawn anchor when pressing Escape' do
        activate_row(@first)
        page.send_keys(:escape)

        aggregate_failures do
          expect(page).to have_no_css(menu_selector)
          expect(page).to have_css('#linkResourceModal')
          expect(page).to have_no_css(picker_node_selector(@first, '.spawn-anchor'))
          expect(page).to have_css("#{picker_node_selector(@first)} > .node-row .record-title", focused: true)
          expect(page).to have_button(confirm_label, disabled: true)
        end
      end

      it 'keeps the spawn anchor when focus leaves the menu via Tab' do
        activate_row(@first)
        page.send_keys(:tab)

        aggregate_failures do
          expect(page).to have_no_css(menu_selector)
          expect(page).to have_css('#linkResourceModal')
          expect(page).to have_css(picker_node_selector(@first, '.spawn-anchor'))
        end
      end
    end

    describe 'choosing a placement' do
      before { open_parent_picker(@resource) }

      context 'before a top-level component' do
        before { choose_placement(@parent, :before) }

        it 'shows the placeholder before the current component' do
          aggregate_failures do
            expect(page).to have_css(
              "#{root_list_selector} > li.spawn-placeholder.indent-level-1 + li##{infinite_tree_node_id_for(@parent)}"
            )
            expect(page).to have_no_css(picker_node_selector(@parent, '.spawn-anchor'))
            expect(page).to have_css(
              "#{placeholder_selector} .record-title > .glyphicon-asterisk:first-child[aria-hidden='true']"
            )
            expect(page).to have_css("#{placeholder_selector} .record-title", text: placeholder_text)
            expect(page).to have_no_css("#{placeholder_selector}.spawn-anchor")
            expect(page).to have_no_css("#{placeholder_selector}.current")
            expect(page).to have_no_css(menu_selector)
            expect(page).to have_css('#linkResourceModal #addSelectedButton:not([disabled])', focused: true)
          end
        end

        it 'leaves the parent blank and sets the position' do
          confirm_placement

          expect_spawn_placement(parent: nil, position: 1)
        end
      end

      context 'after a top-level component with children' do
        it 'places the component after the whole subtree' do
          expand_tree_node(@parent.uri)
          expect(page).to have_css(picker_node_selector(@nested_second))
          choose_placement(@parent, :after)

          expect(page).to have_css(
            "#{root_list_selector} > li##{infinite_tree_node_id_for(@parent)} + li.spawn-placeholder.indent-level-1"
          )

          confirm_placement

          expect_spawn_placement(parent: nil, position: 2)
        end
      end

      context 'as the child of a collapsed component' do
        it 'expands the component and places the component first among its children' do
          choose_placement(@parent, :child)

          expect(page).to have_css(
            "#{picker_node_selector(@parent, "[aria-expanded='true']")} > ol.node-children > " \
            "li.spawn-placeholder.indent-level-2:first-child + li##{infinite_tree_node_id_for(@nested_first)}"
          )

          confirm_placement

          expect_spawn_placement(parent: @parent, position: 0)
        end
      end

      context 'before a nested component' do
        it "uses the nested component's parent and position" do
          expand_tree_node(@parent.uri)
          choose_placement(@nested_second, :before)

          expect(page).to have_css(
            "li##{infinite_tree_node_id_for(@nested_first)} + li.spawn-placeholder.indent-level-2 + " \
            "li##{infinite_tree_node_id_for(@nested_second)}"
          )

          confirm_placement

          expect_spawn_placement(parent: @parent, position: 1)
        end
      end

      context 'as the child of a component without children' do
        it 'adds a temporary child list that leaves with the placeholder' do
          leaf = picker_node_selector(@last)

          choose_placement(@last, :child)
          expect(page).to have_css(
            "#{leaf}[aria-expanded='true'] > ol.node-children[data-tree-level='2'] > li.spawn-placeholder:only-child"
          )

          choose_placement(@last, :before)

          aggregate_failures do
            expect(page).to have_css(
              "#{root_list_selector} > li.spawn-placeholder + li##{infinite_tree_node_id_for(@last)}"
            )
            expect(page).to have_no_css("#{leaf} > ol.node-children")
            expect(page).to have_no_css("#{leaf}[aria-expanded]")
          end
        end
      end

      it 'keeps one placeholder that cannot be activated' do
        choose_placement(@first, :before)
        choose_placement(@first, :after)
        find("#{placeholder_selector} .record-title").click

        aggregate_failures do
          expect(page).to have_css(placeholder_selector, count: 1)
          expect(page).to have_css("#{root_list_selector} > li##{infinite_tree_node_id_for(@first)} + li.spawn-placeholder")
          expect(page).to have_no_css('#linkResourceModal li.node.spawn-anchor')
          expect(page).to have_no_css(picker_node_selector(@first, '.spawn-anchor'))
          expect(page).to have_no_css(menu_selector)
        end
      end

      it 'discards the placement when another row is activated' do
        choose_placement(@first, :before)
        activate_row(@last)

        aggregate_failures do
          expect(page).to have_no_css(placeholder_selector)
          expect(page).to have_css(picker_node_selector(@last, '.spawn-anchor'))
          expect(page).to have_button(confirm_label, disabled: true)
        end
      end
    end

    describe 'with the keyboard' do
      before { open_parent_picker(@resource) }

      it 'activates a title with Enter and moves among placements with the arrow keys' do
        title_of(@first).send_keys(:enter)

        expect(page).to have_css(picker_node_selector(@first, '.spawn-anchor'))
        expect(page).to have_css("#{menu_selector} .add-items-before", focused: true)

        page.send_keys(:arrow_down)
        expect(page).to have_css("#{menu_selector} .add-items-as-children", focused: true)
        page.send_keys(:arrow_down)
        expect(page).to have_css("#{menu_selector} .add-items-after", focused: true)
        page.send_keys(:arrow_down)
        expect(page).to have_css("#{menu_selector} .add-items-before", focused: true)
        page.send_keys(:arrow_up)
        expect(page).to have_css("#{menu_selector} .add-items-after", focused: true)

        page.send_keys(:enter)

        aggregate_failures do
          expect(page).to have_css("#{root_list_selector} > li##{infinite_tree_node_id_for(@first)} + li.spawn-placeholder")
          expect(page).to have_css('#linkResourceModal #addSelectedButton:not([disabled])', focused: true)
        end
      end

      it 'activates a title with Space' do
        title_of(@last).send_keys(:space)

        aggregate_failures do
          expect(page).to have_css(picker_node_selector(@last, '.spawn-anchor'))
          expect(page).to have_css("#{menu_selector} .add-items-before", focused: true)
        end
      end

    end

    context 'when the Resource has no components' do
      it 'places the component as the only child of the Resource' do
        open_parent_picker(@empty_resource)

        aggregate_failures do
          expect(page).to have_css("#{root_list_selector} > li.spawn-placeholder:only-child")
          expect(page).to have_no_css('#linkResourceModal li.node.spawn-anchor')
          expect(page).to have_button(confirm_label, disabled: false)
        end

        confirm_placement

        expect_spawn_placement(parent: nil, position: 0)
      end
    end

    context 'when it is closed and reopened' do
      it 'disconnects its tree observer each time' do
        visit "/archival_objects/new?accession_id=#{@accession.id}"
        expect(page).to have_css("#linkResourceModal input[value='#{@resource.uri}']")
        install_tree_observer_spy

        3.times do
          choose_resource(@resource)
          wait_for_parent_picker
          activate_row(@first)
          find('#linkResourceModal .modal-footer .btn-cancel').click
          expect(page).to have_no_css('#linkResourceModal')
          expect_spawn_placement(parent: nil, position: '')

          find('.record-toolbar .select-resource button').click
          expect(page).to have_css("#linkResourceModal input[value='#{@resource.uri}']")
        end

        expect(tree_observer_stats).to eq(
          'created' => 3, 'disconnected' => 3, 'observedAfterDisconnect' => 0
        )
      end
    end
  end

  describe 'choosing another Resource after a nested placement' do
    before do
      open_parent_picker(@resource)
      choose_placement(@parent, :child)
      confirm_placement
      expect_spawn_placement(parent: @parent, position: 0)

      find('.record-toolbar .select-resource button').click
    end

    it 'clears the placement so a top-level position can be chosen' do
      expect_spawn_placement(parent: nil, position: '')

      choose_resource(@resource)
      wait_for_parent_picker
      expect(page).to have_no_css('#linkResourceModal li.node.spawn-anchor, #linkResourceModal li.spawn-placeholder')

      choose_placement(@first, :before)
      confirm_placement

      expect_spawn_placement(parent: nil, position: 0)
    end

    it 'clears the placement when a different Resource is chosen' do
      choose_resource(@other_resource)
      wait_for_parent_picker

      aggregate_failures do
        expect(location_query['resource_id']).to eq(@other_resource.id.to_s)
        expect_spawn_placement(parent: nil, position: '')
        expect(page).to have_css(picker_node_selector(@other_component))
        expect(page).to have_no_css(picker_node_selector(@parent))
        expect(page).to have_no_css('#linkResourceModal li.node.spawn-anchor, #linkResourceModal li.spawn-placeholder')
      end
    end
  end

  describe 'saving a top-level placement' do
    it 'saves the component between its chosen siblings' do
      open_parent_picker(@ordering_resource)
      choose_placement(@ordering_first, :after)
      confirm_placement
      expect_spawn_placement(parent: nil, position: 1)

      spawned_id = save_spawned_component(@ordering_resource)
      expect(page).to have_css("#infinite-tree-container li#archival_object_#{spawned_id}.current")

      expect(root_child_uris).to eq(
        [
          @ordering_first.uri,
          "/repositories/#{@repo.id}/archival_objects/#{spawned_id}",
          @ordering_second.uri
        ]
      )
    end
  end

  private

  def create_component(resource, title, parent: nil)
    attributes = { resource: { 'ref' => resource.uri }, title: title }
    attributes[:parent] = { 'ref' => parent.uri } if parent

    create(:archival_object, attributes)
  end

  def open_parent_picker(resource)
    visit "/archival_objects/new?accession_id=#{@accession.id}&resource_id=#{resource.id}"
    wait_for_parent_picker
  end

  def wait_for_parent_picker
    expect(page).to have_css('#linkResourceModal .infinite-tree-parent-picker li.root.node')
  end

  def choose_resource(resource)
    find("#linkResourceModal input[value='#{resource.uri}']").click
    find('#linkResourceModal #addSelectedButton').click
  end

  def picker_node_selector(record, state = '')
    "#linkResourceModal #infinite-tree-container li##{infinite_tree_node_id_for(record)}#{state}"
  end

  def title_of(record)
    find("#{picker_node_selector(record)} > .node-row .record-title")
  end

  def activate_row(record)
    title_of(record).click
    expect(page).to have_css(menu_selector)
  end

  # @param placement [Symbol] :before, :child, or :after
  def choose_placement(record, placement)
    activate_row(record)
    within(menu_selector) { click_button menu_label(placement) }
    expect(page).to have_css(placeholder_selector)
  end

  def menu_label(placement)
    key = { before: 'before', child: 'child', after: 'after' }.fetch(placement)

    I18n.t("archival_object._frontend.messages.spawn_menu_#{key}")
  end

  def confirm_placement
    find('#linkResourceModal #addSelectedButton').click
    expect(page).to have_no_css('#linkResourceModal')
  end

  # @return [String] id of the saved Archival Object
  def save_spawned_component(resource)
    select 'Class', from: 'archival_object_level_'
    find(".save-changes button[type='submit']").click

    expect(page).to have_current_path(
      %r{/resources/#{resource.id}/edit#tree::archival_object_\d+\z}, url: true
    )
    wait_for_infinite_tree_pane_ready

    page.current_url[/archival_object_(\d+)\z/, 1]
  end

  def location_query
    Rack::Utils.parse_query(URI.parse(page.current_url).query)
  end

  # @param parent [Object, nil] parent record, or nil when the Resource is the parent
  # @param position [Integer, String] expected position; '' when cleared
  def expect_spawn_placement(parent:, position:)
    parent_input = find('#archival_object_parent_', visible: :all)

    aggregate_failures 'spawn placement in the form and URL' do
      if parent
        expect(parent_input[:name]).to eq('archival_object[parent][ref]')
        expect(parent_input.value).to eq(parent.uri)
        expect(location_query['archival_object_id']).to eq(parent.id.to_s)
      else
        expect(parent_input[:name]).to eq('archival_object[parent]')
        expect(parent_input.value).to eq('')
        expect(location_query).not_to have_key('archival_object_id')
      end

      expect(find('#archival_object_position_', visible: :all).value).to eq(position.to_s)
    end
  end

  # DOCUMENTED EXCEPTION: there is no DOM signal for a disconnected
  # IntersectionObserver, so count InfiniteTree observers (rooted at the tree
  # container) as they are created, disconnected, and reused.
  def install_tree_observer_spy
    page.execute_script(<<~JS)
      (function () {
        var stats = { created: 0, disconnected: 0, observedAfterDisconnect: 0 };
        var NativeIntersectionObserver = window.IntersectionObserver;

        window.IntersectionObserver = class extends NativeIntersectionObserver {
          constructor(callback, options) {
            super(callback, options);
            this.isTreeObserver = !!(options && options.root && options.root.id === 'infinite-tree-container');
            if (this.isTreeObserver) stats.created += 1;
          }

          observe(target) {
            if (this.isTreeObserver && this.wasDisconnected) stats.observedAfterDisconnect += 1;
            return super.observe(target);
          }

          disconnect() {
            if (this.isTreeObserver && !this.wasDisconnected) {
              this.wasDisconnected = true;
              stats.disconnected += 1;
            }
            return super.disconnect();
          }
        };

        window.__treeObserverStats = stats;
      })();
    JS
  end

  def tree_observer_stats
    page.evaluate_script('window.__treeObserverStats')
  end
end
