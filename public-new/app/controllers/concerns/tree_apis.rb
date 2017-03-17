module TreeApis
  extend ActiveSupport::Concern
  # fetch the tree to be manipulated by other methods in this controller
  # TODO: try/catch for non 200 responses
#   def fetch_tree(node_uri)
#     tree = archivesspace.get_tree(node_uri)
# #      Pry::ColorPrinter.pp(tree)
# #      Pry::ColorPrinter.pp(archivesspace.get_full_tree(node_uri))
#     Tree.new(tree)
#   end
  # create the contents for breadcrumbs
  def get_path(tree)
    tree.breadcrumb
  end
  
end
