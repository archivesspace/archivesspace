class Tree
  include ManipulateNode

  attr_reader :json, :breadcrumb, :children

  def initialize(tree_json)
    @json = tree_json

    @breadcrumb = prepare_breadcrumb
  end

  def [](k)
    @json[k]
  end

  def dig(k)
    @json.dig(k)
  end

  private

  def prepare_breadcrumb
    crumbs = []

    if !json['path_to_root'].blank?
      path = ASUtils.wrap(json['path_to_root'])
      path.each_with_index {|node, i|
        crumbs << {
          :crumb => title_for_node(node, path[0..i]),
          :uri => node['record_uri'] || ''
        }
      }
    end

    crumbs
  end

  def title_for_node(node, previous_nodes)
    title = node['title'] || ''

    if ['classification', 'classification_term'].include?(node['node_type'])
      title = "#{previous_nodes.map {|c| c['identifier']}.join('/')} #{node['title']}"
    end

    process_mixed_content(title)
  end
end