class ArkUpdateController < ApplicationController

  set_access_control  "administer_system" => [:update]

  def update
    uri = "#{JSONModel::HTTP.backend_url}#{params[:uri]}/ark_name"

    response = JSONModel::HTTP::post_json(URI(uri), params[:ark_name])

    if response.code == '200'
      render :plain => "OK"
    else
      err = ASUtils.json_parse(response.body)
      render :plain => ASUtils.to_json(err.fetch('error')), :status => response.code
    end
  end

end

