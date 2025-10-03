module TreeNodes

  def breadcrumb
    crumbs = []

    # add all ancestors to breadcrumb
    path_to_root.each_with_index do |node, level|
      crumbs << {
        :uri => breadcrumb_uri_for_node(node),
        :type => node['jsonmodel_type'],
        :crumb => breadcrumb_title_for_node(node, level),
        :identifier => breadcrumb_identifier(node, node['jsonmodel_type'])
      }
    end

    # and now yourself
    crumbs << {
      :uri => '',
      :type => primary_type,
      :crumb => display_string,
      :identifier => breadcrumb_identifier(self, primary_type)
    }

    crumbs
  end


  def breadcrumb_identifier(record, type)
    case type
    when 'resource'
      if resolved_resource
        id_0 = resolved_resource['id_0']
        id_1 = resolved_resource['id_1']
        id_2 = resolved_resource['id_2']
        id_3 = resolved_resource['id_3']

        id_components = [id_0, id_1, id_2, id_3].reject {|i| i.nil? }
        id_components.join("-")
      end
    end
  end


  def breadcrumb_uri_for_node(node)
    node['node'].nil? ? node.fetch('root_record_uri') : node.fetch('node')
  end


  def breadcrumb_title_for_node(node, _)
    require 'pry-debugger-jruby'; binding.pry
    MultipleTitlesHelper.determine_primary_title(node.fetch('titles'), $locale) #*archival_object node coming back with single title field
  end


  def ancestors
    ancestor_uris = raw.fetch('ancestors', nil)

    return [] if ancestor_uris.blank? || raw['_resolved_ancestors'].nil?

    ASUtils.wrap(ancestor_uris.reverse.map {|uri|
      ASUtils.wrap(raw['_resolved_ancestors'].fetch(uri, nil)).first
    }).compact
  end

  private

  def id
    uri.match(/[0-9]+$/).to_s
  end

  def path_to_root
    begin
      archives_space_client.get_raw_record("#{root_node_uri}/tree/node_from_root_#{id}").fetch(id)
    rescue RecordNotFound => e
      $stderr.puts "RecordNotFound: #{"#{root_node_uri}/tree/node_from_root_#{id}"}"
      []
    end
  end
end
