module TreeNodes

  def breadcrumb
    crumbs = []

    # add all ancestors to breadcrumb
    path_to_root.each do |node|
      crumbs << {
        :uri => node['node'].nil? ? node.fetch('root_record_uri') : node.fetch('node'),
        :crumb => node.fetch('title')
      }
    end

    # and now yourself
    crumbs << {
      :uri => '',
      :crumb => display_string
    }

    crumbs
  end

  private

  def id
    uri.match(/[0-9]+$/).to_s
  end

  def path_to_root
    archives_space_client.get_raw_record("#{root_node_uri}/tree/node_from_root_#{id}").fetch(id)
  end
end