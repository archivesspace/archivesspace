require 'spec_helper'
require 'rails_helper'

describe SessionController, type: :controller do
  describe "GET #check_pui_session" do
    before(:each) do
      set_repo($repo)
      url = URI.parse(AppConfig[:backend_url] + '/users/admin/login')
      request = Net::HTTP::Post.new(url.request_uri)
      request.set_form_data('expiring' => 'false',
                            'password' => 'admin')
      response = do_http_request(url, request)
      JSONModel::HTTP.current_backend_session = ASUtils.json_parse(response.body)['session']
    end

    context "with session with permissions" do
      before(:each) do
        user = build(:json_user).save(password: '123')
        user = User.find(user)
        group = create(:json_group,
                       member_usernames: [user.username],
                       grants_permissions: ['view_repository'])
        session = User.login(user.username, '123')
        User.establish_session(controller, session, user.username)
      end

      it "returns a username, session, and view pui is true" do
        response = get :check_pui_session, params: { }
        parsed_response = JSON.parse(response.body)

        expect(parsed_response['username']).not_to be_nil
        expect(parsed_response['session']).not_to be_nil
        expect(parsed_response['view_pui']).to be_truthy
      end
    end

    context "with session but no permissions" do
      before(:each) do
        user = build(:json_user).save(password: '456')
        user = User.find(user)
        group = create(:json_group,
                       member_usernames: [user.username],
                       grants_permissions: [])
        session = User.login(user.username, '456')
        User.establish_session(controller, session, user.username)
      end

      it "returns a username, session, and view pui is false" do
        response = get :check_pui_session, params: { }
        parsed_response = JSON.parse(response.body)

        expect(parsed_response['username']).not_to be_nil
        expect(parsed_response['session']).not_to be_nil
        expect(parsed_response['view_pui']).not_to be_truthy
      end
    end
  end
end
