# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe AccessionsController, type: :controller do
  render_views

  describe 'record title field' do
    before(:each) do
      set_repo($repo)
      session = User.login('admin', 'admin')
      User.establish_session(controller, session, 'admin')
      controller.session[:repo_id] = JSONModel.repository
      allow(AppConfig).to receive(:[]).with(:allow_mixed_content_title_fields) { true }
      allow(AppConfig).to receive(:[]).and_call_original
    end

    it 'does not support mixed content by default' do
      get :new
      expect(response.body).to have_css('#accession_title_.form-control:not(.mixed-content)')
    end

    it 'supports mixed content when enabled' do
      allow(AppConfig).to receive(:[]).with(:allow_mixed_content_title_fields) { true }
      get :new
      expect(response.body).to have_css('#accession_title_.form-control.mixed-content')
    end
  end

  describe 'inline creation' do
    before(:each) do
      set_repo($repo)
      session = User.login('admin', 'admin')
      User.establish_session(controller, session, 'admin')
      controller.session[:repo_id] = JSONModel.repository
    end

    describe 'GET new with inline parameter' do
      it 'renders the new partial when inline=true' do
        get :new, params: { inline: true }

        result = Capybara.string(response.body)

        aggregate_failures do
          expect(result).to have_css('form.aspace-record-form')
          expect(result).to have_field('accession[title]')
          expect(result).not_to have_css('form#accession_form')
        end
      end

      it 'renders the full new page when inline is not set' do
        get :new
        expect(response.body).to have_css('form.aspace-record-form#accession_form')
      end
    end

    describe 'POST create with inline parameter' do
      it 'returns JSON when inline=true and data is valid' do
        now = Time.now.to_i

        post :create, params: {
          inline: true,
          accession: {
            id_0: "TEST_#{now}",
            id_1: '001',
            title: "Test Accession #{now}",
            accession_date: '2026-01-05'
          }
        }

        expect(response.content_type).to match(%r{application/json})

        json = JSON.parse(response.body)

        aggregate_failures do
          expect(json['title']).to eq("Test Accession #{now}")
          expect(json['id_0']).to eq("TEST_#{now}")
          expect(json['id_1']).to eq('001')
          expect(json['accession_date']).to eq('2026-01-05')
          expect(json['uri']).to match(%r{/repositories/\d+/accessions/\d+})
        end
      end

      it 're-renders the partial with errors when inline=true and data is invalid' do
        post :create, params: {
          inline: true,
          accession: {
            title: 'Incomplete Accession',
            accession_date: '2026-01-05'
          }
        }

        result = Capybara.string(response.body)

        aggregate_failures do
          expect(result).to have_css('form.aspace-record-form')
          expect(result).to have_css('.alert.alert-danger')
          expect(result).to have_field('accession[title]', with: 'Incomplete Accession')
        end
      end

      it 'redirects to edit page when inline is not set and data is valid' do
        now = Time.now.to_i

        post :create, params: {
          accession: {
            id_0: "TEST_#{now}",
            title: "Regular Accession #{now}",
            accession_date: '2026-01-05'
          }
        }

        aggregate_failures do
          expect(response).to redirect_to(action: :edit, id: assigns(:accession).id)
          expect(flash[:success]).to match(/Accession.*created/i)
        end
      end
    end
  end
end
