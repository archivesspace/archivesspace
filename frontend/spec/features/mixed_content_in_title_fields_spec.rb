# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Mixed Content in title fields', js: true do
  before(:all) do
    @repo = create(:repo, repo_code: "mixed_content_test_#{Time.now.to_i}")
    set_repo(@repo)

    @now = Time.now.to_i
    @agent = create(:agent_person,
      names: [build(
        :name_person,
        primary_name: "<title>Agent Person #{@now}</title>"
      )]
    )
    @subject = create(:subject,
      terms: [build(:term, {term: "<emph>Subject #{@now}</emph>", term_type: 'temporal'})]
    )
    @do = create(:digital_object, title: "<title>Digital object #{@now}</title>")
    @doc = create(:digital_object_component,
      title: "<emph render='italic'>Digital object component #{@now}</emph>",
      digital_object: { ref: @do.uri }
    )
    @classification = create(:classification, title: "<emph>Classification #{@now}</emph>")
    @acc = create(:accession, title: "<title>Accession #{@now}</title>")
    @acc2 = create(:accession, title: "<emph>Accession 2 #{@now}</emph>")
    @resource = create(:resource,
      title: "<title>Mixed Content #{@now}</title>",
      instances: [
        {
          instance_type: 'digital_object',
          digital_object: { ref: @do.uri }
        }
      ],
      related_accessions: [
        {
          ref: @acc2.uri
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
      title: "<title>Archival Object #{@now}</title>",
      resource: { ref: @resource.uri },
      accession_links: [
        {
          ref: @acc2.uri
        }
      ]
    )

    run_indexer

    @emph_selector = '.emph.render-none'
    @emph_italic_selector = '.emph.render-italic'
    @title_selector = '.emph.render-none'
  end

  before(:each) do
    login_admin
    select_repository(@repo)
  end

  describe 'should render as HTML' do
    context 'in the main record heading' do
      def selector(view, ead_selector)
        if view == 'show'
          ".record-pane > div:first-child > h2:first-child span#{ead_selector}"
        else
          ".record-pane > h2 > span#{ead_selector}"
        end
      end

      def assert_heading(path, selector, expected_text)
        visit path
        expect(page).to have_css selector, text: expected_text
      end

      context 'for accession' do
        before(:each) do
          @path = "/accessions/#{@acc2.id}"
        end

        it 'show view' do
          assert_heading @path, selector('show', @emph_selector), "Accession 2 #{@now}"
        end

        it 'edit view' do
          assert_heading "#{@path}/edit", selector('edit', @emph_selector), "Accession 2 #{@now}"
        end
      end

      context 'for resource' do
        before(:each) do
          @path = "/resources/#{@resource.id}"
        end

        it 'show view' do
          assert_heading @path, selector('show', @title_selector), "Mixed Content #{@now}"
        end

        it 'edit view' do
          assert_heading "#{@path}/edit", selector('edit', @title_selector), "Mixed Content #{@now}"
        end
      end

      context 'for archival object' do
        it 'show view' do
          path = "/resources/#{@resource.id}/#tree::archival_object_#{@ao.id}"
          assert_heading path, selector('show', @title_selector), "Archival Object #{@now}"
        end

        it 'edit view' do
          path = "/resources/#{@resource.id}/edit#tree::archival_object_#{@ao.id}"
          assert_heading path, selector('edit', @title_selector), "Archival Object #{@now}"
        end
      end

      context 'for digital object' do
        before(:each) do
          @path = "/digital_objects/#{@do.id}"
        end

        it 'show view' do
          assert_heading @path, selector('show', @title_selector), "Digital object #{@now}"
        end

        it 'edit view' do
          assert_heading "#{@path}/edit", selector('edit', @title_selector), "Digital object #{@now}"
        end
      end

      context 'for digital object component' do
        it 'show view' do
          path = "/digital_objects/#{@do.id}/#tree::digital_object_component_#{@doc.id}"
          assert_heading path, selector('show', @emph_italic_selector), "Digital object component #{@now}"
        end

        it 'edit view' do
          path = "/digital_objects/#{@do.id}/edit#tree::digital_object_component_#{@doc.id}"
          assert_heading path, selector('edit', @emph_italic_selector), "Digital object component #{@now}"
        end
      end

      context 'for subject' do
        before(:each) do
          @path = "/subjects/#{@subject.id}"
        end

        it 'show view' do
          assert_heading @path, selector('show', @emph_selector), "Subject #{@now}"
        end

        it 'edit view' do
          assert_heading "#{@path}/edit", selector('edit', @emph_selector), "Subject #{@now}"
        end
      end

      context 'for agent' do
        before(:each) do
          @path = "/agents/agent_person/#{@agent.id}"
        end

        it 'show view' do
          assert_heading @path, selector('show', @title_selector), "Agent Person #{@now}"
        end

        it 'edit view' do
          assert_heading "#{@path}/edit", selector('edit', @title_selector), "Agent Person #{@now}"
        end
      end

      context 'for classification' do
        before(:each) do
          @path = "/classifications/#{@classification.id}"
        end

        it 'show view' do
          assert_heading @path, selector('show', @emph_selector), "Classification #{@now}"
        end

        it 'edit view' do
          assert_heading "#{@path}/edit", selector('edit', @emph_selector), "Classification #{@now}"
        end
      end
    end

    context 'in the title field of the show view' do
      it 'for accessions' do
        visit "/accessions/#{@acc2.id}"
        expect(page).to have_css "#basic_information span#{@emph_selector}", text: "Accession 2 #{@now}"
      end

      it 'for resources' do
        visit "/resources/#{@resource.id}"
        expect(page).to have_css "#basic_information span#{@title_selector}", text: "Mixed Content #{@now}"
      end

      it 'for archival objects' do
        visit "/resources/#{@resource.id}/#tree::archival_object_#{@ao.id}"
        expect(page).to have_css "#basic_information span#{@title_selector}", text: "Archival Object #{@now}"
      end

      it 'for digital objects' do
        visit "/digital_objects/#{@do.id}"
        expect(page).to have_css "#basic_information span#{@title_selector}", text: "Digital object #{@now}"
      end

      it 'for digital object components' do
        visit "/digital_objects/#{@do.id}/#tree::digital_object_component_#{@doc.id}"
        expect(page).to have_css "#basic_information span#{@emph_italic_selector}", text: "Digital object component #{@now}"
      end

      it 'for classifications' do
        visit "/classifications/#{@classification.id}"
        expect(page).to have_css "#basic_information span#{@emph_selector}", text: "Classification #{@now}"
      end

      it 'for subjects' do
        visit "/subjects/#{@subject.id}"
        expect(page).to have_css "#terms span#{@emph_selector}", text: "Subject #{@now}"
      end

      it 'for agents' do
        visit "/agents/agent_person/#{@agent.id}"
        expect(page).to have_css "#identity_information span#{@title_selector}", text: "Agent Person #{@now}"
      end

      it 'for classification terms' do
        visit "/classifications/#{@classification.id}"
        expect(page).to have_css "#basic_information span#{@emph_selector}", text: "Classification #{@now}"
      end
    end

    context 'in the largetree' do
      it 'for resources and archival objects' do
        visit "/resources/#{@resource.id}"
        expect(page).to have_css "#tree-container a.record-title span#{@title_selector}", text: "Mixed Content #{@now}"
        expect(page).to have_css "#tree-container a.record-title span#{@title_selector}", text: "Archival Object #{@now}"
      end

      it 'for digital objects and digital object components' do
        visit "/digital_objects/#{@do.id}"
        expect(page).to have_css "#tree-container a.record-title span#{@title_selector}", text: "Digital object #{@now}"
        expect(page).to have_css "#tree-container a.record-title span#{@emph_italic_selector}", text: "Digital object component #{@now}"
      end

      it 'for classifications and classification terms' do
        visit "/classifications/#{@classification.id}"
        expect(page).to have_css "#tree-container a.record-title span#{@emph_selector}", text: "Classification #{@now}"
        expect(page).to have_css "#tree-container a.record-title span#{@emph_selector}", text: "Classification #{@now}"
      end
    end

    context 'in search results' do
      it 'from a search' do
        visit "/search?q=Mixed+Content+#{@now}"
        expect(page).to have_css "#tabledSearchResults .title > span#{@title_selector}", text: "Mixed Content #{@now}"
      end

      describe 'in an index view' do
        it 'for accessions' do
          visit '/accessions'
          expect(page).to have_css "#tabledSearchResults .title > span#{@emph_selector}", text: "Accession 2 #{@now}"
        end

        it 'for resources and archival objects' do
          visit '/resources'
          click_link 'Show Components'
          expect(page).to have_css "#tabledSearchResults .title > span#{@title_selector}", text: "Mixed Content #{@now}"
          expect(page).to have_css "#tabledSearchResults .title > span#{@title_selector}", text: "Archival Object #{@now}"
        end

        it 'for digital objects and digital object components' do
          visit '/digital_objects'
          click_link 'Show Components'
          expect(page).to have_css "#tabledSearchResults .title > span#{@title_selector}", text: "Digital object #{@now}"
          expect(page).to have_css "#tabledSearchResults .title > span#{@emph_italic_selector}", text: "Digital object component #{@now}"
        end

        it 'for subjects' do
          visit '/subjects'
          expect(page).to have_css "#tabledSearchResults .title > span#{@emph_selector}", text: "Subject #{@now}"
        end

        it 'for agents' do
          visit '/agents/'
          click_link 'Person'
          expect(page).to have_css "#tabledSearchResults .title > span#{@title_selector}", text: "Agent Person #{@now}"
        end

        it 'for classifications' do
          visit "/classifications"
          expect(page).to have_css "#tabledSearchResults .title > span#{@emph_selector}", text: "Classification #{@now}"
        end

        xit 'for events' do
          # See https://archivesspace.atlassian.net/browse/ANW-2373
        end

        xit 'for assessments' do
          # See https://archivesspace.atlassian.net/browse/ANW-2373
        end
      end
    end

    context 'in all linker tokens' do
      context 'in, for example, an accession' do
        describe 'show view' do
          before(:each) do
            visit "/accessions/#{@acc2.id}"
          end

          it 'for Related Resources' do
            expect(page).to have_css '#accession_related_resources_ .token span.emph.render-none', text: "Mixed Content #{@now}"
          end

          it 'for Component Links' do
            expect(page).to have_css '#accession_component_links_ .token span.emph.render-none', text: "Archival Object #{@now}"
          end
        end

        describe 'edit view' do
          before(:each) do
            visit "/accessions/#{@acc2.id}/edit"
          end

          it 'for Related Resources' do
            expect(page).to have_css '#accession_related_resources_ .token-input-list span.emph.render-none', text: "Mixed Content #{@now}"
          end

          it 'for Component Links' do
            expect(page).to have_css '#accession_component_links_ .token-input-list span.emph.render-none', text: "Archival Object #{@now}"
          end
        end
      end

      context 'in, for example, a resource' do
        describe 'show view' do
          before(:each) do
            visit "/resources/#{@resource.id}"
          end

          it 'for Related Accessions' do
            expect(page).to have_css '#resource_related_accessions_ .token span.emph.render-none', text: "Accession 2 #{@now}"
          end

          it 'for Linked Agents' do
            expect(page).to have_css '#resource_linked_agents_ .token span.emph.render-none', text: "Agent Person #{@now}"
          end

          it 'for Subjects' do
            expect(page).to have_css '#resource_subjects_ .token span.emph.render-none', text: "Subject #{@now}"
          end

          it 'for Instances' do
            expect(page).to have_css '#resource_instances_ .token span.emph.render-none', text: "Digital object #{@now}", visible: false
          end

          it 'for Classifications' do
            expect(page).to have_css '#resource_classifications_ .token span.emph.render-none', text: "Classification #{@now}"
          end
        end

        describe 'edit view' do
          before(:each) do
            visit "/resources/#{@resource.id}/edit"
          end

          it 'for Related Accessions' do
            expect(page).to have_css '#resource_related_accessions_ .token-input-list span.emph.render-none', text: "Accession 2 #{@now}"
          end

          it 'for Linked Agents' do
            expect(page).to have_css '#resource_linked_agents_ .token-input-list span.emph.render-none', text: "Agent Person #{@now}"
          end

          it 'for Subjects' do
            expect(page).to have_css '#resource_subjects_ .token-input-list span.emph.render-none', text: "Subject #{@now}"
          end

          it 'for Instances' do
            expect(page).to have_css '#resource_instances_ .token-input-list span.emph.render-none', text: "Digital object #{@now}", visible: false
          end

          it 'for Classifications' do
            expect(page).to have_css '#resource_classifications_ .token-input-list span.emph.render-none', text: "Classification #{@now}"
          end
        end
      end
    end

    context 'in flash messages' do
      it 'for accessions' do
        visit "/accessions/#{@acc2.id}/edit"
        check 'Publish?'
        click_button 'Save'
        expect(page).to have_css "#form_messages span#{@emph_selector}", text: "Accession 2 #{@now}"
      end

      it 'for resources' do
        visit "/resources/#{@resource.id}/edit"
        check 'Publish?'
        click_button 'Save'
        expect(page).to have_css "#form_messages span#{@title_selector}", text: "Mixed Content #{@now}"
      end

      it 'for archival objects' do
        visit "/resources/#{@resource.id}/edit#tree::archival_object_#{@ao.id}"
        check 'Publish?'
        click_button 'Save'
        wait_for_ajax
        expect(page).to have_css "#form_messages span#{@title_selector}", text: "Archival Object #{@now}"
      end

      it 'for digital objects' do
        visit "/digital_objects/#{@do.id}/edit"
        check 'Publish?'
        click_button 'Save'
        expect(page).to have_css "#form_messages span#{@title_selector}", text: "Digital object #{@now}"
      end

      it 'for digital object components' do
        visit "/digital_objects/#{@do.id}/edit#tree::digital_object_component_#{@doc.id}"
        check 'Publish?'
        click_button 'Save'
        wait_for_ajax
        expect(page).to have_css "#form_messages span#{@emph_italic_selector}", text: "Digital object component #{@now}"
      end

      it 'for classifications' do
        visit "/classifications/#{@classification.id}/edit"
        fill_in 'Description', with: @now
        click_button 'Save'
        expect(page).to have_css "#form_messages span#{@emph_selector}", text: "Classification #{@now}"
      end

      xit 'for subjects' do
        # Flash messages don't reference the record's title
      end

      xit 'for agents' do
        # Flash messages don't reference the record's title
      end
    end
  end
end
