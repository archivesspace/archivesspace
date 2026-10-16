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
    @markup_date_ao = create(:archival_object,
      title: 'Record Tree Markup Date',
      level: 'file',
      resource: { ref: @resource.uri },
      dates: [{
        'jsonmodel_type' => 'date',
        'date_type' => 'single',
        'label' => 'creation',
        'expression' => '<b class="injected">Probe</b>'
      }],
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

  def title_css(record)
    "##{record.jsonmodel_type}_#{record.id} > .node-row .node-title"
  end

  def expand_css(record)
    "##{record.jsonmodel_type}_#{record.id} > .node-row .node-expand"
  end

  context 'on a resource' do
    before(:each) { visit @resource.uri }

    it 'marks the root as the current node' do
      expect(tree).to have_css("li.root.current#resource_#{@resource.id}")
      expect(tree).to have_css("#{title_css(@resource)}[aria-current='page']")
    end

    it 'renders raw title parts such as dates as text, not HTML' do
      node = tree.find(title_css(@markup_date_ao))

      expect(node).to have_text('<b class="injected">Probe</b>')
      expect(tree).not_to have_css('.injected')
    end

    it 'links nodes to their record pages' do
      expect(tree).to have_css("#{title_css(@siblings.first)}[href$='#{@siblings.first.uri}']")
    end

    it 'uses plain lists and keeps links and buttons in the tab order' do
      expect(tree).not_to have_css('[role]')
      expect(tree).not_to have_css('[tabindex]')
      expect(tree).not_to have_css('[aria-hidden="true"].node-expand')
    end
  end

  context 'on a deeply nested archival object' do
    before(:each) { visit @item.uri }

    it 'expands its ancestors and marks it current' do
      expect(tree).to have_css("#archival_object_#{@series.id}[data-is-expanded='true']")
      expect(tree).to have_css("#archival_object_#{@file.id}[data-is-expanded='true']")
      expect(tree).to have_css("#archival_object_#{@item.id}.current")
      expect(tree).to have_css("#{title_css(@item)}[aria-current='page']")
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
      expect(tree).to have_css("#{expand_css(@file)}[aria-expanded='true']")
    end
  end

  context 'on a digital object component' do
    before(:each) { visit @doc.uri }

    it 'renders the digital object hierarchy' do
      expect(tree).to have_css("li.root#digital_object_#{@do.id}")
      expect(tree).to have_css("#digital_object_component_#{@doc.id}.current[data-is-expanded='true']")
      expect(tree).to have_css("#digital_object_component_#{@doc_child.id}")
      expect(tree).to have_css("#{title_css(@doc_child)}[href$='#{@doc_child.uri}']")
    end
  end

  context 'on a classification term' do
    before(:each) { visit @term.uri }

    it 'renders classification titles with identifiers' do
      expect(tree).to have_css("li.root#classification_#{@classification.id} .node-title", text: 'RTC. Record Tree Classification')
      expect(tree).to have_css("#{title_css(@term)}", text: 'RTT. Record Tree Term')
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
    end

    def focus(css)
      tree.find(css).execute_script('this.focus()')
    end

    def press(*keys)
      page.active_element.send_keys(*keys)
    end

    # The button's accessible name: the label not hidden by CSS for the node's state
    def expand_button_label(record)
      tree.find(expand_css(record)).evaluate_script(<<~JS)
        Array.from(this.querySelectorAll('.node-expand-label'))
          .filter(el => getComputedStyle(el).display !== 'none')
          .map(el => el.textContent)
          .join('')
      JS
    end

    def focused_matches?(css)
      page.active_element.evaluate_script("this.matches(#{css.to_json})")
    end

    it 'tabs through expand buttons and titles in order' do
      focus(title_css(@series))

      press(:tab)
      expect(focused_matches?(expand_css(@file))).to be true

      press(:tab)
      expect(focused_matches?(title_css(@file))).to be true

      press(%i[shift tab])
      press(%i[shift tab])
      expect(focused_matches?(title_css(@series))).to be true

      press(%i[shift tab])
      expect(focused_matches?(expand_css(@series))).to be true
    end

    it 'toggles a node with Return and Space on its expand button' do
      focus(expand_css(@series))

      press(:enter)
      expect(tree).to have_css("#archival_object_#{@series.id}[data-is-expanded='false']")
      expect(tree).to have_css("#{expand_css(@series)}[aria-expanded='false']")

      press(:space)
      expect(tree).to have_css("#archival_object_#{@series.id}[data-is-expanded='true']")
      expect(tree).to have_css("#{expand_css(@series)}[aria-expanded='true']")
    end

    it 'loads children when a collapsed node is expanded from the keyboard' do
      focus(expand_css(@file))

      press(:enter)
      expect(tree).to have_css("#archival_object_#{@file.id} > .node-children > #archival_object_#{@item.id}")
    end

    it 'names the action each expand button will take' do
      expect(expand_button_label(@series)).to eq('Collapse Record Tree Series')
      expect(expand_button_label(@file)).to eq('Expand Record Tree File')

      focus(expand_css(@series))
      press(:enter)

      expect(tree).to have_css("#archival_object_#{@series.id}[data-is-expanded='false']")
      expect(expand_button_label(@series)).to eq('Expand Record Tree Series')
    end

    it "follows a title link to the record's page with Return" do
      focus(title_css(@file))

      press(:enter)
      expect(page).to have_current_path(@file.uri)
    end
  end
end
