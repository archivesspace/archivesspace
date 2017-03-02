class ClassificationTerm < Classification
  include TreeNodes

  def root_node_uri
    json.fetch('classification').fetch('ref')
  end

end
