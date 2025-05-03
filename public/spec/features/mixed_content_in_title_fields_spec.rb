# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Mixed Content in title fields', js: true do
  before(:all) do
    @now = Time.now.to_i
    @subject = create(:subject,
      terms: [build(:term, {term: "<emph>Subject #{@now}</emph>", term_type: 'temporal'})]
    )
    @agent = create(:agent_person,
      names: [build(
        :name_person,
        primary_name: "<title>Agent Person #{@now}</title>"
      )],
      publish: true
    )
    @agent2 = create(:agent_person,
      names: [build(
          :name_person,
          primary_name: "<emph>Agent Person 2 #{@now}</emph>"
        ),
        build(
          :name_person,
          primary_name: "<title>Agent Person 2 Alt #{@now}</title>"
        )
      ],
      publish: true,
      related_agents: [
        JSONModel(:agent_relationship_parentchild).new({ :ref => @agent.uri, :relator => 'is_child_of' }).to_hash
      ],
    )
    @classification = create(:classification, title: "<emph>Classification #{@now}</emph>", publish: true)
    @classification_term = create(:classification_term,
      title: "<title>Classification Term #{@now}</title>",
      classification: { 'ref' => @classification.uri }
    )
    @acc = create(:accession, title: "<emph>Accession #{@now}</emph>", publish: true)
    @do = create(:digital_object, title: "<title>Digital Object #{@now}</title>", publish: true)
    @doc = create(:digital_object_component,
      title: "<emph render='italic'>Digital Object Component #{@now}</emph>",
      digital_object: { ref: @do.uri },
      publish: true
    )
    @resource = create(:resource,
      title: "<title>Resource #{@now}</title>",
      publish: true,
      instances: [
        {
          instance_type: 'digital_object',
          digital_object: { ref: @do.uri }
        }
      ],
      related_accessions: [
        {
          ref: @acc.uri
        }
      ],
      linked_agents: [
        {
          ref: @agent.uri,
          role: 'creator'
        }
      ],
      subjects: [
        {
          ref: @subject.uri
        }
      ],
      classifications: [
        {
          ref: @classification.uri
        }
      ]
    )
    @ao = create(:archival_object,
      title: "<emph>Archival Object #{@now}</emph>",
      publish: true,
      resource: { ref: @resource.uri },
      accession_links: [
        {
          ref: @acc.uri
        }
      ]
    )

    run_indexers

    @emph_selector = '.emph'
    @emph_italic_selector = '.emph.italic'
    @title_selector = '.title'

    @frontend_emph_selector = '.emph.render-none'
    @frontend_emph_italic_selector = '.emph.render-italic'
    @frontend_title_selector = '.emph.render-none'
  end

  after(:all) do
    @ao&.delete
    @resource&.delete
    @doc&.delete
    @do&.delete
    @acc&.delete
    @classification_term&.delete
    @classification&.delete
    @agent2&.delete
    @agent&.delete
    @subject&.delete
  end

  describe 'should render as HTML' do
    context 'in the main record headings' do
      it 'for resources' do
        visit @resource.uri
        expect(page).to have_css "h1 > span#{@title_selector}", text: "Resource #{@now}"
      end

      it 'for archival objects' do
        visit @ao.uri
        expect(page).to have_css "h1 > span#{@emph_selector}", text: "Archival Object #{@now}"
      end

      it 'for digital objects' do
        visit @do.uri
        expect(page).to have_css "h1 > span#{@title_selector}", text: "Digital Object #{@now}"
      end

      it 'for digital object components' do
        visit @doc.uri
        expect(page).to have_css "h1 > span#{@emph_italic_selector}", text: "Digital Object Component #{@now}"
      end

      it 'for accessions' do
        visit @acc.uri
        expect(page).to have_css "h1 > span#{@emph_selector}", text: "Accession #{@now}"
      end

      it 'for subjects' do
        visit @subject.uri
        expect(page).to have_css "h1 > span#{@emph_selector}", text: "Subject #{@now}"
      end

      it 'for agents' do
        visit @agent.uri
        expect(page).to have_css "h1 > span#{@title_selector}", text: "Agent Person #{@now}"
      end

      it 'for classifications' do
        visit @classification.uri
        expect(page).to have_css "h1 > span#{@emph_selector}", text: "Classification #{@now}"
      end
    end

    context 'in record breadcrumbs' do
      it 'for resources and archival objects' do
        visit @ao.uri
        expect(page).to have_css ".breadcrumb span#{@title_selector}", text: "Resource #{@now}"
        expect(page).to have_css ".breadcrumb span#{@emph_selector}", text: "Archival Object #{@now}"
      end

      it 'for digital objects and digital object components' do
        visit @doc.uri
        expect(page).to have_css ".breadcrumb span#{@title_selector}", text: "Digital Object #{@now}"
        expect(page).to have_css ".breadcrumb span#{@emph_italic_selector}", text: "Digital Object Component #{@now}"
      end

      it 'for accessions' do
        visit @acc.uri
        expect(page).to have_css ".breadcrumb span#{@emph_selector}", text: "Accession #{@now}"
      end

      it 'for classifications and classification terms' do
        visit @classification_term.uri
        expect(page).to have_css ".breadcrumb span#{@emph_selector}", text: "Classification #{@now}"
        expect(page).to have_css ".breadcrumb span#{@title_selector}", text: "Classification Term #{@now}"
      end

      it 'in search results' do
        visit '/search'
        fill_in 'Enter your search terms', with: "Digital Object #{@now}"
        click_button 'Search'
        expect(page).to have_css ".search-results .result_context span#{@frontend_title_selector}", text: "Resource #{@now}"
      end
    end

    context 'in search results' do
      it 'from a search' do
        visit '/search'
        fill_in 'Enter your search terms', with: "Resource #{@now}"
        click_button 'Search'
        expect(page).to have_css ".search-results .record-title > span#{@title_selector}", text: "Resource #{@now}"
      end

      describe 'from an index view' do
        it 'for resources' do
          visit '/repositories/resources'
          expect(page).to have_css ".search-results .record-title > span#{@title_selector}", text: "Resource #{@now}"
        end

        it 'for accessions' do
          visit '/accessions'
          expect(page).to have_css ".search-results .record-title > span#{@emph_selector}", text: "Accession #{@now}"
        end

        it 'for subjects' do
          visit '/subjects'
          expect(page).to have_css ".search-results .record-title > span#{@emph_selector}", text: "Subject #{@now}"
        end

        it 'for agents' do
          visit '/agents'
          expect(page).to have_css ".search-results .record-title > span#{@title_selector}", text: "Agent Person #{@now}"
        end

        it 'for classifications' do
          visit '/classifications'
          expect(page).to have_css ".search-results .record-title > span#{@emph_selector}", text: "Classification #{@now}"
        end
      end
    end

    context 'in the largetree' do
      it 'for resources and archival objects' do
        visit @resource.uri
        expect(page).to have_css "#tree-container .record-title > span#{@frontend_title_selector}", text: "Resource #{@now}"
        expect(page).to have_css "#tree-container .record-title > span#{@frontend_emph_selector}", text: "Archival Object #{@now}"
      end

      it 'for digital objects and digital object components' do
        visit @do.uri
        expect(page).to have_css "#tree-container .record-title > span#{@frontend_title_selector}", text: "Digital Object #{@now}"
        expect(page).to have_css "#tree-container .record-title > span#{@frontend_emph_italic_selector}", text: "Digital Object Component #{@now}"
      end

      it 'for classifications and classification terms' do
        visit @classification.uri
        expect(page).to have_css "#tree-container .record-title > span#{@frontend_emph_selector}", text: "Classification #{@now}"
        expect(page).to have_css "#tree-container .record-title > span#{@frontend_title_selector}", text: "Classification Term #{@now}"
      end
    end

    context 'in a resource infinite view' do
      before(:each) do
        visit "#{@resource.uri}/collection_organization"
      end

      it 'infinite tree sidebar' do
        expect(page).to have_css ".infinite-tree .node-title > span#{@frontend_title_selector}", text: "Resource #{@now}"
        expect(page).to have_css ".infinite-tree .node-title > span#{@frontend_emph_selector}", text: "Archival Object #{@now}"
      end

      it 'infinite records section' do
        expect(page).to have_css "#infinite-records-container .record-title > span#{@title_selector}", text: "Resource #{@now}"
        expect(page).to have_css "#infinite-records-container .record-title > span#{@emph_selector}", text: "Archival Object #{@now}"
      end
    end

    context 'for linked records content' do
      describe 'in, for example, a resource record' do
        before(:each) do
          visit @resource.uri
        end

        it 'agents list' do
          expect(page).to have_css ".upper-record-details .agents_list span#{@title_selector}", text: "Agent Person #{@now}"
        end

        it 'subjects list' do
          expect(page).to have_css "#res_accordion #subj_list span#{@emph_selector}", text: "Subject #{@now}"
        end

        it 'classifications list' do
          expect(page).to have_css "#res_accordion #classifications_list span#{@emph_selector}", text: "Classification #{@now}"
        end

        it 'instances list' do
          expect(page).to have_css "#res_accordion #linked_digital_objects_list span#{@frontend_emph_selector}", text: "Digital Object #{@now}"
        end

        it 'accessions list' do
          expect(page).to have_css "#res_accordion #related_accessions_list span#{@emph_selector}", text: "Accession #{@now}"
        end
      end

      describe 'in, for example, a digital object record' do
        before(:each) do
          visit @do.uri
        end

        it 'records list' do
          expect(page).to have_css "#res_accordion #linked_instances_list span#{@frontend_title_selector}", text: "Resource #{@now}"
        end
      end

      describe 'in an agent record' do
        before(:each) do
          visit @agent2.uri
        end

        it 'name forms list' do
          expect(page).to have_css "#agent_accordion #names_panel span#{@title_selector}", text: "Agent Person 2 Alt #{@now}"
        end

        it 'related agents list' do
          expect(page).to have_css "#agent_accordion #related_agents_list span#{@title_selector}", text: "Agent Person #{@now}"
        end
      end
    end
  end
end
