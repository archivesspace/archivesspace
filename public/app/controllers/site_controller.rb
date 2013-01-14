class SiteController < ApplicationController
  def index
  end

  def search
    @criteria = {
      :q => params[:q],
      :page => params[:page] || 1
    }

    @criteria['type[]'] = Array(params[:type]) if not params[:type].blank?
    @criteria['exclude[]'] = params[:exclude] if not params[:exclude].blank?

    @search_data = JSONModel::HTTP::get_json("/repositories/#{@repository.id}/search", @criteria)

    render "search/results"
  end
end
