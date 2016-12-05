module ManipulateNode
  extend ActiveSupport::Concern
  require 'nokogiri'


  # the beginning of processing mixed content  nodes for titles, notes, etc.
  #TODO:  look at replacing these gsubs with syntax like:
  #  @xml.xpath("//item").each do |item|
  #    item.name = "li"
  #  end

  def process_mixed_content(in_txt)
    return if !in_txt
    txt = in_txt.strip
    txt = txt.gsub("chronlist>", "ul>")
      .gsub("chronitem>", "li>")
    txt = txt.gsub("list>", "ul>")
      .gsub("item>", "li>")
      .gsub(/\n\n/,"<br /><br />")
    txt = txt.gsub("xlink\:type=\"simple\"", "")
    @frag = Nokogiri::XML.fragment(txt)
    move_list_heads
    @frag.traverse { |el| 
      # we don't do anything at the top level of the fragment or if it's text
      node_check(el) if el.parent && !el.text?
      el.content = el.text.gsub("\"", "&quot;") if el.text?
    }
    # replace the inline quotes with &quot;
    @frag.to_xml.to_s.gsub("&amp;quot;", "&quot;")
  end

  # strips all xml markup; used for things like titles.
  def strip_mixed_content(in_text)
    @frag = Nokogiri::XML.fragment(in_text)
    @frag.content
  end

  # provides inheritance information, with markup!
  def inheritance(struct = nil)
    text = ''
    unless struct.blank? || struct['level'].blank? || struct['direct']
      level = I18n.t("inherit.#{struct['level'].downcase}")
      text = '<span class="inherit">' + I18n.t('inherit.inherited', :level => level) + '</span>'
    end
    text
  end

  private 

# because ead lists have heads; gotta deal with them
  def move_list_heads
    @frag.xpath('//ul/head').each do |head|
      h5 = head
      h5.name = 'h5'
      parent = h5.parent
      parent.add_previous_sibling(h5)
    end
  end

  def node_check(el)
    newnode = el.clone
    if newnode.key? "render"
      newnode = process_render(newnode)
    elsif newnode.name.match(/ptr$/) 
      newnode = process_pointer(newnode)
    elsif  newnode.name.match(/^extref/)
      newnode = process_anchor(newnode)
    elsif newnode.name == 'lb'
      newnode.name = 'br'
    else
      if !newnode.name.match(/^(p|ul|li|br|h5)$/)
        if newnode.name == 'date'
          newnode.remove_attribute('calendar')
          newnode.remove_attribute('era')
        end
        clss = newnode['class'] || ''
        role = newnode['role'] ||''
        unless role.blank?
          newnode.remove_attribute('role')
        end
        newnode['class']  = "#{newnode.name} #{clss} #{role}".strip 
        newnode.name = newnode.name == 'accession' ? 'div' : 'span'
      end
    end
    newnode = process_anchor(newnode) if newnode.name != 'a'
    el.replace(newnode)
  end

  def process_anchor(node)
    href = node['href']  
    href.strip! if href
    href = node['xlink:href'] if href.blank?
    target = node['target']
    target.strip! if target
    return node if href.blank? && target.blank? 
    ttl = node['title']
    anchornode = node.document.create_element('a')
    anchornode['href'] = href || "\##{target}"
    if ttl
      anchornode['title'] = ttl.strip
    elsif node.name == 'extref'
      ttl == node.content
    end 
    if node.name == 'extref'
      anchornode['target'] = 'extref'
      ttl = node.content
    end
    if !node.name.match(/ptr$/) && node.name != 'extref'
      node.remove_attribute('href') if node['href']
#      node.remove_attribute('xlink:href') if node['xlink:href']
#      node.remove_attribute('title')
      anchornode.add_child(node.to_xml)
    else
      ttl = ttl || 'link'
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
