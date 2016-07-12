class SearchController < ApplicationController

  PAGE_NUMBERS_TO_SHOW = 10

  def search
    @query = params.require(:q)
    page = Integer(params.fetch(:page, "1"))

    @results = archivesspace.search(@query, page)

    lower_page = [(page - PAGE_NUMBERS_TO_SHOW / 2), 1].max
    upper_page = [(lower_page + PAGE_NUMBERS_TO_SHOW), @results['last_page'] + 1].min

    @pages = Range.new(lower_page, upper_page, true)
  end

end
