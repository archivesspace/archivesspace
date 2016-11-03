module TreeApis
  extend ActiveSupport::Concern
  # fetch the tree to be manipulated by other methods in this controller
  # TODO: try/catch for non 200 responses
  def fetch_tree(node_uri)
    tree = archivesspace.get_tree(node_uri)
#      Pry::ColorPrinter.pp(tree)
#      Pry::ColorPrinter.pp(archivesspace.get_full_tree(node_uri))
    tree
  end
  # create the contents for breadcrumbs
  def get_path(tree)
    path_to_root = {}
    Rails.logger.debug("PATH_TO_ROUTE: #{tree['path_to_root']}")
    if !tree['path_to_root'].blank?
      path_to_root = tree['path_to_root'].map {|node|
        {
          :crumb => process_mixed_content(node['title'] || ''),
          :uri => node['record_uri'] || ''
        }
      }
    end
    path_to_root
  end
  
end
