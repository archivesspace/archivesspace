class ClassificationTerm < Classification
  include TreeNodes

  def root_node_uri
    json.fetch('classification').fetch('ref')
  end

  # we add the identifier to the breadcrumb title
  def breadcrumb_title_for_node(node, level)
    json_path_to_root = json.fetch('path_from_root')
    json_identifiers = json_path_to_root[0..level].map{|n| n.fetch('identifier')}

    "#{json_identifiers.join(I18n.t('classification_term.identifier_separator'))}#{I18n.t('classification.identifier_separator')} #{super}"
  end

end
