class CiteController < ApplicationController
  # this is the backupt to producing the citation in the absence of javascript

  skip_before_filter  :verify_authenticity_token

  def show
    @url = params.fetch(:url,'')
    @cite = params.fetch(:cite, '')
    @page_title = I18n.t('actions.cite')
    render
  end
end
