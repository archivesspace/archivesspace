# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe TopContainersController, type: :controller do
  render_views

  before(:all) do
    set_repo($repo)
    @top_container = create(:top_container, indicator: 'Test Box 1')
    @resource = create(:resource)
  end

  before(:each) do
    set_repo($repo)
    session = User.login('admin', 'admin')
    User.establish_session(controller, session, 'admin')
    controller.session[:repo_id] = JSONModel.repository
  end

  describe 'access_top_containers' do
    it 'renders the manage_for_record partial' do
      get :access_top_containers

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_css('#topContainersManageForRecord')
    end

    it 'shows a success flash message when saved=true' do
      get :access_top_containers, params: { saved: 'true' }

      result = Capybara.string(response.body)
      expect(result).to have_css('.alert.alert-success')
    end

    it 'does not show a flash message when saved is not set' do
      get :access_top_containers

      result = Capybara.string(response.body)
      expect(result).not_to have_css('.alert.alert-success')
    end

    it 'does not show a flash message when saved=false' do
      get :access_top_containers, params: { saved: 'false' }

      result = Capybara.string(response.body)
      expect(result).not_to have_css('.alert.alert-success')
    end

    it 'accepts a resource record_uri without error' do
      get :access_top_containers, params: {
        record_uri: @resource.uri,
        record_type: 'resource',
        record_title: @resource.title
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_css('#topContainersManageForRecord')
    end
  end

  describe 'inline show' do
    it 'renders the show_inline partial when inline=true' do
      get :show, params: { id: @top_container.id, inline: true }

      result = Capybara.string(response.body)
      aggregate_failures do
        expect(result).to have_content('Test Box 1')
        expect(result).not_to have_css('nav.navbar')
      end
    end

    it 'renders the full show page when inline is not set' do
      get :show, params: { id: @top_container.id }

      expect(response.body).to have_css('nav.navbar')
    end
  end

  describe 'inline edit' do
    it 'renders the edit_inline partial when inline=true' do
      get :edit, params: { id: @top_container.id, inline: true }

      result = Capybara.string(response.body)
      aggregate_failures do
        expect(result).to have_css('form.aspace-record-form#edit_top_container_inline')
        expect(result).not_to have_css('nav.navbar')
      end
    end

    it 'renders the full edit page when inline is not set' do
      get :edit, params: { id: @top_container.id }

      expect(response.body).to have_css('nav.navbar')
    end
  end

  describe 'inline update' do
    it 'returns JSON when inline=true and data is valid' do
      new_indicator = "Updated Box #{Time.now.to_i}"
      current = JSONModel(:top_container).find(@top_container.id)

      post :update, params: {
        id: @top_container.id,
        inline: true,
        top_container: { indicator: new_indicator, lock_version: current.lock_version }
      }

      aggregate_failures do
        expect(response.content_type).to match(%r{application/json})
        json = JSON.parse(response.body)
        expect(json['indicator']).to eq(new_indicator)
        expect(json['uri']).to match(%r{/repositories/\d+/top_containers/\d+})
      end
    end

    it 're-renders the edit_inline partial with errors when inline=true and indicator is blank' do
      current = JSONModel(:top_container).find(@top_container.id)

      post :update, params: {
        id: @top_container.id,
        inline: true,
        top_container: { indicator: '', lock_version: current.lock_version }
      }

      result = Capybara.string(response.body)
      aggregate_failures do
        expect(result).to have_css('form.aspace-record-form#edit_top_container_inline')
        expect(result).to have_css('.alert.alert-danger')
      end
    end

    it 'redirects to show page when inline is not set and data is valid' do
      current = JSONModel(:top_container).find(@top_container.id)

      post :update, params: {
        id: @top_container.id,
        top_container: { indicator: "Redirect Box #{Time.now.to_i}", lock_version: current.lock_version }
      }

      expect(response).to redirect_to(action: :show, id: @top_container.id)
    end
  end
end
