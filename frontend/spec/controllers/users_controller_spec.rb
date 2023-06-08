require 'spec_helper'
require 'rails_helper'

describe UsersController, type: :controller do

  before(:each) do
    set_repo($repo)
    url = URI.parse(AppConfig[:backend_url] + '/users/admin/login')
    request = Net::HTTP::Post.new(url.request_uri)
    request.set_form_data('expiring' => 'false',
                          'password' => 'admin')
    response = do_http_request(url, request)

    if response.code == '200'
      auth = ASUtils.json_parse(response.body)

      JSONModel::HTTP.current_backend_session = auth['session']
    else
      raise "Authentication to backend failed: #{response.body}"
    end

    allow(controller).to receive(:user_must_have).and_return(true)
    user = build(:json_user).save(password: "saa2020")
    user = User.find(user)
    group = create(:json_group,
                   member_usernames: [user.username],
                   grants_permissions: [])
    session = User.login(user.username, "saa2020")
    User.establish_session(controller, session, user.username)
    controller.send(:load_repository_list)
  end

  it 'validates password and confirmation password' do
    post :update_password, params: { password: "foo", confirm_password: "bar" }
    expect(response).to redirect_to('/users/edit_password')
    expect(request.flash[:error]).to eq("Passwords do not match.")
  end

  it 'ensures password is minimally complex' do
    post :update_password, params: { password: "foo", confirm_password: "foo" }
    expect(response).to redirect_to('/users/edit_password')
    expect(request.flash[:error]).to match(/too easy to guess/)
  end

end
