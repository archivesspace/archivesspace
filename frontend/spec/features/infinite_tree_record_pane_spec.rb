require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree Record Pane', js: true do
  context 'on the resources show view' do
    let(:now) { Time.now.to_i }
    let(:repo) { create(:repo, repo_code: "resources_test_#{now}") }
    let(:resource) { create(:resource, title: "Resource #{now}") }
    let(:ao) { create(:archival_object, resource: { 'ref' => resource.uri }, title: "Archival Object #{now}") }

    before(:each) do
      set_repo(repo)
      login_admin
      select_repository(repo)
      ao
    end

    context 'at page load' do
      describe 'shows the readonly form for the resource' do
        it 'when there is no document uri fragment' do
          visit "/resources/#{resource.id}"
          wait_for_ajax
          form = page.find('#infinite-tree-record-pane .readonly-context')

          within(form) do
            expect(page).to have_css('h2', text: resource.title)
            expect(page).to have_field('uri', with: resource.uri)
          end
        end

        it 'when the document uri fragment references the resource' do
          visit "/resources/#{resource.id}#tree::resource_#{resource.id}"
          wait_for_ajax
          form = page.find('#infinite-tree-record-pane .readonly-context')

          within(form) do
            expect(page).to have_css('h2', text: resource.title)
            expect(page).to have_field('uri', with: resource.uri)
          end
        end
      end

      describe 'shows the readonly form for an archival object' do
        it 'when the document uri fragment references the archival object' do
          visit "/resources/#{resource.id}#tree::archival_object_#{ao.id}"
          wait_for_ajax
          form = page.find('#infinite-tree-record-pane .readonly-context')

          within(form) do
            expect(page).to have_css('h2', text: ao.title)
            expect(page).to have_field('uri', with: ao.uri)
          end
        end
      end
    end

    context 'when an infinite tree node record title is clicked' do
      it 'shows the readonly form for the new current record' do
        visit "/resources/#{resource.id}"
        wait_for_ajax
        form = page.find('#infinite-tree-record-pane .readonly-context')

        click_link ao.title
        wait_for_ajax

        within(form) do
          expect(page).to have_css('h2', text: ao.title)
          expect(page).to have_field('uri', with: ao.uri)
        end

        click_link resource.title
        wait_for_ajax

        within(form) do
          expect(page).to have_css('h2', text: resource.title)
          expect(page).to have_field('uri', with: resource.uri)
        end
      end
    end
  end
end
