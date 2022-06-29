class ArkNameController < ApplicationController

  def show
    # looks up ARK name in backend, and redirects to the right place based on the results
    resolve_ark_url(params)
  end

  private

  def resolve_ark_url(params)
    ark = "ark:/#{params[:ark_id]}"

    json_response = send_ark_request(ark)
    redirect_to_entity_url(json_response, ark)
  end


  def send_ark_request(ark)
    criteria = {:aq => AdvancedQueryBuilder
                         .new
                         .and('ark_name', ark, 'text', true, false)
                         .build
                         .to_json}

    results = archivesspace.advanced_search('/search', page = 1, criteria)

    if results.records.length == 1
      results.first.json
    else
      return {"type" => "not_found"}
    end
  end


  def redirect_to_entity_url(json_response, uri)
    if json_response['type'] == 'not_found'
      ark_not_resolved(uri)
    else
      if is_external?(json_response['external_ark_url'])
        redirect_to json_response['external_ark_url']
      else
        redirect_to PrefixHelper.app_prefix(json_response['uri'])
      end
    end
  end

  def is_external?(ark)
    AppConfig[:arks_allow_external_arks] && ark && !ark.start_with?(AppConfig[:public_proxy_url])
  end
end
