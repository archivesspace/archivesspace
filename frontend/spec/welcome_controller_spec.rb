require 'spec_helper'


describe WelcomeController do

  it "should welcome all guests" do 
    expect(get :index).to have_http_status(200)
  end

end
