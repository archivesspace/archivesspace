class WelcomeController < ApplicationController
  def show
    @page_title = I18n.t 'brand.welcome_page_title'
    @search = Search.new(params)
    render
  end
end
