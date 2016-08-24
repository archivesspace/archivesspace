module ManipulateNode
  extend ActiveSupport::Concern
  require 'nokogiri'

  # the beginning of processing mixed content  nodes for titles, notes, etc.
  def process_mixed_content(txt)
    return if !txt
    txt.strip!
    txt.gsub!("list>", "ul>")
    txt.gsub!("item>", "li>")
#    if txt.gsub!(/\n\n/,"</div><div>")
#      txt = "<div>#{txt}</div>"
#Rails.logger.debug(txt)
#   end
    frag = Nokogiri::XML.fragment(txt)
    frag.traverse { |el| 
      # we don't do anything at the top level of the fragment or if it's text
      node_check(el) if el.parent && !el.text?
    }
    frag.to_xml
  end

  private 

  def node_check(el)
    newnode = el.clone
    if newnode.key? "render"
      newnode = process_render(newnode)
    elsif newnode.name.match(/ptr$/)
      newnode = process_pointer(newnode)
    elsif newnode.name == 'lb'
      newnode.name = 'br'
    else
      if !newnode.name.match(/p|ul|li/)
        clss = newnode['class'] || ''
        newnode['class']  = "#{newnode.name} #{clss}".strip 
        newnode.name = 'span'
      end
    end
    newnode = process_anchor(newnode) if newnode.name != 'a'
    el.replace(newnode)
  end

  def process_anchor(node)
    href = node['href']
    href.strip? if href
    target = node['target']
    target.strip? if target
    return node if !href && target.blank? 
    ttl = node['title']
    anchornode = node.document.create_element('a')
    anchornode['href'] = href || "\##{target}"
    anchornode['title'] = ttl.strip if ttl
    if !node.name.match(/ptr$/)
      node.remove_attribute('href')
      node.remove_attribute('title')
      anchornode.add_child(node.to_xml)
    else
      ttl = ttl | 'link'
      anchornode.add_child(ttl)
    end
    anchornode
  end

  # right now, assumes that show == embed is an embedde object; otherwise an anchor
  def process_pointer(node)
    if node['show'] == "embed"
      newnode = node.document.create_element('embed')
      newnode['src'] = node['href']
      newnode['class'] = node.name
      newnode['id'] = node['id'] if node['id']
      return newnode
    else
      return process_anchor(node)
    end
  end

  def process_render(node)
    name = node.name
    node.name = case node['render']
             when /quote/
              'q'
             when /alt/
              'q'
             when /super/ 
              'sup'
              when /sub/
              'sub'
              when /underline/
              'u'
            else
              'span'
            end
    clss = node['class'] || ""
    clss = "#{name} #{clss}"
    %w{altrender bold single italic smcaps nonproport}.each do |w|
      if node['render'].include?(w)
        clss = "#{w} #{clss}"
      end
    end
    node['class'] = clss.strip if !clss.blank?
    node.remove_attribute('render')
    return node
   end
end
