# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Classification search results subgroups', js: true do
  before(:all) do
    @now = Time.now.to_i
    @repo = create(:repo, repo_code: "subgroups_test_#{@now}")
    set_repo(@repo)

    @classifications = (1..2).map do |i|
      classification = create(:classification,
        identifier: "SGC#{i}",
        title: "Subgroups Classification #{i} #{@now}",
        publish: true
      )
      term = create(:classification_term,
        identifier: "SGT#{i}",
        title: "Subgroups Term #{i} #{@now}",
        classification: { ref: classification.uri },
        publish: true
      )

      { classification: classification, term: term }
    end

    run_indexers
  end

  before(:each) do
    visit "/repositories/#{@repo.id}/classifications"
  end

  def row_for(classification)
    find(".recordrow[data-uri='#{classification.uri}']")
  end

  it 'renders an independent tree per result on demand' do
    @classifications.each do |records|
      row = row_for(records[:classification])

      expect(row).not_to have_css('.classification-subgroups-tree .infinite-tree')

      row.find('button.subgroup-toggle').click

      within row do
        expect(page).to have_css(".classification-subgroups-tree li.root#classification_#{records[:classification].id}")
        expect(page).to have_css(
          ".classification-subgroups-tree #classification_term_#{records[:term].id} .node-title[href$='#{records[:term].uri}']",
          text: "#{records[:term].identifier}. Subgroups Term"
        )
        expect(page).not_to have_css('.classification-subgroups-tree .node.current')
      end
    end

    expect(page).to have_css('template#infinite-tree-node-template', visible: :all, count: 1)
  end

  it 'hides and shows the tree without re-rendering it' do
    row = row_for(@classifications.first[:classification])
    toggle = row.find('button.subgroup-toggle')

    toggle.click
    expect(row).to have_css('.classification-subgroups-tree .infinite-tree', count: 1)
    expect(toggle['aria-pressed']).to eq 'true'

    toggle.click
    expect(row).not_to have_css('.classification-subgroups-tree', visible: true)
    expect(toggle['aria-pressed']).to eq 'false'

    toggle.click
    expect(row).to have_css('.classification-subgroups-tree .infinite-tree', count: 1)
  end
end
