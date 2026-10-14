# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

# Record show-page hierarchy sidebar (InfiniteTree, record links)
describe 'Record show page tree', js: true do
  before(:all) do
    @repo = create(:repo, repo_code: "record_tree_test_#{Time.now.to_i}")
    set_repo(@repo)

    @resource = create(:resource, title: 'Record Tree Resource', publish: true)
    @siblings = (1..25).map do |i|
      create(:archival_object,
        title: format('Sibling %02d', i),
        level: 'file',
        resource: { ref: @resource.uri },
        publish: true
      )
    end
    @series = create(:archival_object,
      title: 'Record Tree Series',
      level: 'series',
      resource: { ref: @resource.uri },
      publish: true
    )
    @file = create(:archival_object,
      title: 'Record Tree File',
      level: 'file',
      resource: { ref: @resource.uri },
      parent: { ref: @series.uri },
      publish: true
    )
    @item = create(:archival_object,
      title: 'Record Tree Item',
      level: 'item',
      resource: { ref: @resource.uri },
      parent: { ref: @file.uri },
      publish: true
    )

    @do = create(:digital_object, title: 'Record Tree DO', publish: true)
    @doc = create(:digital_object_component,
      title: 'Record Tree DOC',
      digital_object: { ref: @do.uri },
      publish: true
    )
    @doc_child = create(:digital_object_component,
      title: 'Record Tree DOC Child',
      digital_object: { ref: @do.uri },
      parent: { ref: @doc.uri },
      publish: true
    )

    @classification = create(:classification,
      identifier: 'RTC',
      title: 'Record Tree Classification',
      publish: true
    )
    @term = create(:classification_term,
      identifier: 'RTT',
      title: 'Record Tree Term',
      classification: { ref: @classification.uri },
      publish: true
    )
    @subterm = create(:classification_term,
      identifier: 'RTS',
      title: 'Record Tree Subterm',
      classification: { ref: @classification.uri },
      parent: { ref: @term.uri },
      publish: true
    )

    run_indexers
  end

  let(:tree) { find('#record-tree-container') }

  def treeitem_css(record)
    "##{record.jsonmodel_type}_#{record.id} > .node-row [role='treeitem']"
  end

  context 'on a resource' do
    before(:each) { visit @resource.uri }

    it 'marks the root as the current node' do
      expect(tree).to have_css("li.root.current#resource_#{@resource.id}")
      expect(tree).to have_css("#{treeitem_css(@resource)}[aria-current='page']")
    end

    it 'links nodes to their record pages' do
      expect(tree).to have_css("#{treeitem_css(@siblings.first)}[href$='#{@siblings.first.uri}']")
    end

    it 'makes the current node the single tab stop' do
      expect(tree).to have_css("#{treeitem_css(@resource)}[tabindex='0']")
      expect(tree).to have_css("[role='treeitem'][tabindex='0']", count: 1)
    end
  end

  context 'on a deeply nested archival object' do
    before(:each) { visit @item.uri }

    it 'expands its ancestors and marks it current' do
      expect(tree).to have_css("#archival_object_#{@series.id}[data-is-expanded='true']")
      expect(tree).to have_css("#archival_object_#{@file.id}[data-is-expanded='true']")
      expect(tree).to have_css("#archival_object_#{@item.id}.current")
      expect(tree).to have_css("#{treeitem_css(@item)}[aria-current='page']")
      expect(tree).to have_css('.node.current', count: 1)
    end

    it 'scrolls the tree container, not the page' do
      expect(tree).to have_css("#archival_object_#{@item.id}.current")
      expect(tree.evaluate_script('this.scrollTop')).to be > 0
      expect(page.evaluate_script('window.scrollY')).to eq 0
    end
  end

  context 'on an archival object with children' do
    before(:each) { visit @file.uri }

    it 'expands the current node' do
      expect(tree).to have_css("#archival_object_#{@file.id}.current[data-is-expanded='true']")
      expect(tree).to have_css("#archival_object_#{@file.id} > .node-children > #archival_object_#{@item.id}")
      expect(tree).to have_css("#{treeitem_css(@file)}[aria-expanded='true']")
    end
  end

  context 'on a digital object component' do
    before(:each) { visit @doc.uri }

    it 'renders the digital object hierarchy' do
      expect(tree).to have_css("li.root#digital_object_#{@do.id}")
      expect(tree).to have_css("#digital_object_component_#{@doc.id}.current[data-is-expanded='true']")
      expect(tree).to have_css("#digital_object_component_#{@doc_child.id}")
      expect(tree).to have_css("#{treeitem_css(@doc_child)}[href$='#{@doc_child.uri}']")
    end
  end

  context 'on a classification term' do
    before(:each) { visit @term.uri }

    it 'renders classification titles with identifiers' do
      expect(tree).to have_css("li.root#classification_#{@classification.id} .node-title", text: 'RTC. Record Tree Classification')
      expect(tree).to have_css("#{treeitem_css(@term)}", text: 'RTT. Record Tree Term')
    end

    it 'expands the current term to show its subgroups' do
      expect(tree).to have_css("#classification_term_#{@term.id}.current[data-is-expanded='true']")
      expect(tree).to have_css("#classification_term_#{@term.id} #classification_term_#{@subterm.id}")
    end

    it 'puts the sidebar in the configured position' do
      expect(page).to have_css('#sidebar.infinite-tree-sidebar[data-sidebar-position]')
    end
  end

  describe 'keyboard navigation' do
    before(:each) do
      visit @series.uri
      expect(tree).to have_css("#archival_object_#{@series.id}.current[data-is-expanded='true']")
      tree.find(treeitem_css(@series)).execute_script('this.focus()')
    end

    def press(key)
      page.active_element.send_keys(key)
    end

    def focused_node_id
      page.active_element.evaluate_script("this.closest('.node').id")
    end

    it 'moves to the first child with Right on an expanded node' do
      press(:arrow_right)
      expect(focused_node_id).to eq "archival_object_#{@file.id}"
    end

    it 'expands a collapsed node with Right' do
      press(:arrow_right)
      press(:arrow_right)
      expect(tree).to have_css("#archival_object_#{@file.id}[data-is-expanded='true']")
      expect(tree).to have_css("#{treeitem_css(@file)}[aria-expanded='true']")
      expect(focused_node_id).to eq "archival_object_#{@file.id}"
    end

    it 'collapses an expanded node with Left, then moves to the parent' do
      press(:arrow_left)
      expect(tree).to have_css("#archival_object_#{@series.id}[data-is-expanded='false']")

      press(:arrow_left)
      expect(focused_node_id).to eq "resource_#{@resource.id}"
    end

    it 'moves between visible nodes with Up and Down' do
      press(:arrow_up)
      expect(focused_node_id).to eq "archival_object_#{@siblings.last.id}"

      press(:arrow_down)
      expect(focused_node_id).to eq "archival_object_#{@series.id}"
    end

    it 'keeps a single tab stop on the focused node' do
      press(:arrow_up)
      expect(tree).to have_css("[role='treeitem'][tabindex='0']", count: 1)
      expect(tree).to have_css("#{treeitem_css(@siblings.last)}[tabindex='0']")
    end
  end
end
