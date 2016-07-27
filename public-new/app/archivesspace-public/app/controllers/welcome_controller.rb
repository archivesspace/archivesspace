class WelcomeController < ApplicationController
  def show
    @page_title = "Welcome! A New Day Dawns!"
    render  
  end
end
