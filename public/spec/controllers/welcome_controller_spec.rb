require 'spec_helper'


describe WelcomeController, type: :controller do

  it "should welcome all visitors" do 
    expect(get :show).to have_http_status(200)
  end

end
