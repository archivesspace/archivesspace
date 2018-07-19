class ArkIdentifierController <  ApplicationController

  def show
    # looks up ARK id in backend, and redirects to the right place based on the results
    resolve_ark_url(params)
  end

  private

    def resolve_ark_url(params)
      uri = "/ark:/#{params[:naan]}/#{params[:id]}"

      json_response = send_ark_request(uri)
      redirect_to_entity_url(json_response)
    end


    def send_ark_request(uri)
      url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
      response = JSONModel::HTTP.get_response(url)

      if response
        return JSON.parse(response.body)
      else
        return {"type" => "not_found"}
      end
    end    


    def redirect_to_entity_url(json_response)
      case json_response["type"]
      when "external"
        redirect_to json_response["external_url"]
      when "Resource"
        redirect_to "/repositories/" + json_response["repo_id"].to_s + "/resources/" + json_response["id"].to_s
      when "Accession"
        redirect_to "/repositories/" + json_response["repo_id"].to_s + "/accessions/" + json_response["id"].to_s
      when "DigitalObject"
        redirect_to "/repositories/" + json_response["repo_id"].to_s + "/digital_objects/" + json_response["id"].to_s
      else
        render '/shared/not_found'
      end
    end   
end
