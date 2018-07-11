class GenerateAccessionIdentifiersController < ApplicationController

  skip_before_action :unauthorised_access

  def generate
    response = JSONModel::HTTP::post_form('/plugins/generate_accession_identifiers/next')

    if response.code == '200'
      render :json => ASUtils.json_parse(response.body)
    else
      render :status => 500
    end
  end

end
