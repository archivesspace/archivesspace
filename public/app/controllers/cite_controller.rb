class CiteController < ApplicationController
  # this is the backupt to producing the citation in the absence of javascript

  def show
    @url = params.fetch(:uri, '')
    @cite = params.fetch(:cite, '')
    @page_title = I18n.t('actions.cite')
    render
  end
end
