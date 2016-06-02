class TreesController < ApplicationController

  def fetch
    response = JSONModel::HTTP::get_json("/search/published_tree", :node_uri => params[:node_uri])

    Rails.logger.debug(response.inspect)
    return nil unless response and response.has_key?('tree_json')
    tree = ASUtils.json_parse(response['tree_json'])

    tree['children'] = tree['direct_children'].map {|node|

      if node['title'] =~ /(.+),\s+((\d+-)?\d+)/
        title = $1
        date = $2
      else
        title = node['title']
        date = nil
      end

      title.strip!
      title.sub!(/<title\s+render=['"]italic['"][^>]*>([^<]+)<\/title>/, '<i>\1</i>')

      if node['containers'].length
        node['container_label'] = [node['containers'][0]['type_1'], node['containers'][0]['indicator_1'], node['containers'][0]['type_2'], node['containers'][0]['indicator_2']].compact.join(" ")
      end

      {
        'title' => title,
        'date' => date,
        'id' => node['id'],
        'children' => node['has_children'],
        'record_uri' => node['record_uri'],
        'component_id' => node['component_id'],
        'container_label' => node['container_label']
      }
    }

    render :json => tree['children']
#    render :json => tree['self']['node_type'] == 'resource' ? tree['children'] : tree
  end


  # Yes, this is horrible. The problem is that the ASpace data model really
  # doesn't support what the UI designs seem to call for - a kind of
  # hierarchy of dated boxes and folders under classification nodes.
  # Classification nodes can only link to Resources, which contain
  # Instances and Dates which we try to mangle into the data we want
  # here. Wondering if the resulting UI functionality will be accepted,
  # we don't strive to do better just yet...
  def classification
    id = params[:id]
    uri = "/repositories/#{params[:repo_id]}/classifications/#{id}"
    response = JSONModel::HTTP::get_json("/search/published_tree", :node_uri => uri)

    tree = ASUtils.json_parse(response['tree_json'])

    data = tree['direct_children']
      .map {|child| JSONModel(:classification_term).id_for(child['record_uri'])}
      .map {|id| JSONModel(:classification_term).find(id, :repo_id => params[:repo_id], "resolve[]" => ["linked_records"]) }
      .map {|term|
      term.to_hash.merge({:container_children => term['linked_records']
                     .map {|linked_record| linked_record['_resolved']['instances'].map{|instance| instance.merge({'dates' => linked_record['_resolved']['dates'], 'resource_title' => linked_record['_resolved']['title'], 'resource_data' => JSONModel.parse_reference(linked_record['ref'])})} }
                     .flatten
                     .reject{|instance| instance['instance_type'] == 'digital_object'}
                     .map {|instance|
                     result = {:name => instance['resource_title'], :resource_data => instance['resource_data']}
                     if date = instance['dates'][0]
                       if date['expression']
                         result[:date] = date['expression']
                       elsif date['begin'] || date['end']
                         result[:date] = [date['begin'], date['end']].compact.join('-')
                       end
                     end

                     container = instance['container'] || {}
                     if(container['type_1'] && container['indicator_1'])
                       result[:container_1] = I18n.t("enumerations.container_type.#{container["type_1"]}") + " #{container['indicator_1']}"
                     end

                     if(container['type_2'] && container['indicator_2'])
                       result[:container_2] = I18n.t("enumerations.container_type.#{container["type_2"]}") + " #{container['indicator_2']}"
                     end

                     result
                   }
                 })
    }
    render :json => ASUtils.to_json(data)
  end

end
