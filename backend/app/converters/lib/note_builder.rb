class NoteBuilder

  # note - the empty JSONModel note
  # node - the Nokogiri::XML::Reader object
  def initialize(note, node)
    @note = note
    @node = node
  end

  def build_scopenote_from_unitdate
    @note.type = "scopecontent"
    content = @node.inner_xml
    content.tr!("\n", ' ')
    content.sub!(/\A\s+/m, '')
    content.sub!(/\s+\z/m, '')
    subnote = ASpaceImport::JSONModel(:note_text).new
    subnote.content = content
    @note.subnotes << subnote
  end

  def build_note
    @note.type ||= @node.name
    @note.label ||= extract_label_from_head_tag
    if doc.element_children.empty?
      raise "This is not expected! No children in note node: \n #{@node.inner_xml}"
    end

    titles = []
    children = []

    case @node.name
    when "bioghist"
      process_bioghist
    else
      doc.element_children.each_with_index do |child, i|
        case child.name
        when "head"
          titles << child.inner_html
        when "p", "table", "blockquote"
          add_or_append_to_text_subnote(child)
        when "list"
          add_list_subnote(child, i)
        when "chronlist"
          add_chronlist_subnote(child, titles.last)
        when "archref"
          add_unorderedlist_item(child)
        else # fallback to a text subnote for any unanticipated tags
          add_or_append_to_text_subnote(child)
        end
      end
    end
    @note.subnotes.each do |sn|
      sn.publish = true
      if sn.jsonmodel_type == "note_text"
        sn.content = format_content(sn.content)
      end
    end
  end


  private

  def format_content(content)
    return content if content.nil?
    content.gsub!(%r{\s*</p>\s*<p>\s*}, "\n\n")
    content.gsub!(%r{<p>\s*}, "<p>")
    content.gsub!(%r{\s*</p>}, "</p>")
    content.gsub!(%r{\A\s*<p>}, "")
    content.gsub!(%r{</p>\s*\z}, "")
    content.gsub!(%r{\s*<p>}, "\n\n")
    content.gsub!(%r{</p>\s*}, "\n\n")
    content.strip
  end

  def doc
    inner_xml = @node.inner_xml.gsub("&amp;", "___AMPERSAND___").gsub("&", "___AMPERSAND___").gsub("___AMPERSAND___", "&amp;")
    @doc ||= Nokogiri::XML::DocumentFragment.parse(inner_xml)
    @doc
  end

  def add_or_append_to_text_subnote(node, make_new_subnote=false)
    content = node.to_xml
    content.tr!("\n", ' ')
    content.sub!(/\A\s+/m, '')
    content.sub!(/\s+\z/m, '')
    if !make_new_subnote && (@note.subnotes.size > 0) && \
       (@note.subnotes.last.jsonmodel_type == "note_text")

      @note.subnotes.last.content += "\n#{content}"
    else
      subnote = ASpaceImport::JSONModel(:note_text).new
      subnote.content = content
      @note.subnotes << subnote
    end
  end

  def add_unorderedlist_item(node)
    if @note.subnotes.size > 0 && \
       @note.subnotes.last.jsonmodel_type == "note_unorderedlist"

      content = node.inner_html
      content.tr!("\n", ' ')
      content.sub!(/\A\s+/m, '')
      content.sub!(/\s+\z/m, '')
      @note.subnotes.last.items << content
    else
      subnote = ASpaceImport::JSONModel(:note_unorderedlist).new
      @note.subnotes << subnote
      add_unorderedlist_item(node)
    end
  end

  def add_list_subnote(node, i = nil)
    subnote_type = if node.attr('listtype') == "deflist"
                     :note_definedlist
                   else
                     :note_unorderedlist
                   end

    # coerce to defined list if all elements are defitems
    if subnote_type == :note_unorderedlist && node.element_children.map {|i| i.name }.reject {|n| n == "listhead" }.compact == ["defitem"]
      subnote_type = :note_definedlist
    end

    subnote = ASpaceImport::JSONModel(subnote_type).new
    if i && doc.element_children[i - 1].name == "head"
      subnote.title = doc.element_children[i - 1].text
    end
    node.element_children.each do |item|
      if item.name == "item"
        if subnote_type == :note_definedlist
          raise "<item> tag found in defined list note #{node.to_xml}"
        end
        subnote.items << item.inner_html.sub(/\A\s+/m, '').sub(/\s+\z/m, '')
      elsif item.name == "defitem"
        if subnote_type != :note_definedlist
          raise "<defitem> tag found in non-defined list note #{node.to_xml}"
        end
        value = item.xpath('item').first&.text
        label = item.xpath('label').first&.text
        subnote.items << { label: label, value: value }
      elsif item.name == "listhead"
        subnote.title = item.text.strip.gsub("\n", " ")
      else
        raise "Expecting all <list> children to be <item>s but got a #{item.name} \n \
        See #{doc.inner_html}"
      end

    end
    @note.subnotes << subnote
  end

  def add_chronlist_subnote(child, title = nil)
    chron_note = ASpaceImport::JSONModel(:note_chronology).new()
    child.children.select {|c| c.name == "chronitem"}.each do |chronitem|
      dates = extract_chronitem_dates(chronitem)
      place = extract_place(chronitem)
      chronset_node = chronitem.at_xpath('./chronitemset')
      events = []
      if chronset_node
        events = chronset_node.xpath('./event').map { |e| e.inner_html.strip }
      else
        events = chronitem.xpath('./event').map { |e| e.inner_html.strip }
      end
      chron_note.items.push({
                              place: place,
                              events: events
                            }.merge(dates))
    end

    if title
      chron_note.title = title
    end
    @note.subnotes << chron_note
  end


  def extract_label_from_head_tag
    if doc.element_children.size > 0 && doc.element_children.first.name == 'head'
      return doc.element_children.first.text.strip
    end
    return nil
  end

  def note_profile
    if doc.element_children.map {|c| c.name } == ['head', 'list']
      return :list
    end

    return :default
  end

  def default_text_subnote
    subnote = ASpaceImport::JSONModel(:note_text).new
    subnote.content = @node.inner_xml
    subnote
  end

  def unordered_list_subnote
    subnote = ASpaceImport::JSONModel(:note_unorderedlist).new
    subnote.title = doc.element_children[0].text
    doc.element_children[1].element_children.each do |item|
      subnote.items << item.inner_html
    end
    subnote
  end

  def process_bioghist(bioghist_df=doc, outermost=true)
    titles = []
    children = []
    nested_bioghists = []
    last_head = nil
    make_new_subnote = true

    bioghist_df.children.each do |child|
      keep_track_of_child = true

      case child.name
      when "bioghist"
        last_head = nil
        nested_bioghists << child
        keep_track_of_child = false
      when "head"
        titles << child.inner_html
        last_head = child
      when "p"
        if last_head && !outermost
          add_or_append_to_text_subnote(last_head, make_new_subnote)
          last_head = nil
          make_new_subnote = false
        end
        add_or_append_to_text_subnote(child)
        make_new_subnote = false
      when "table"
        add_or_append_to_text_subnote(child)
      when "list"
        add_list_subnote(child)
      when "chronlist"
        add_chronlist_subnote(child, titles.last)
      end

      # capture all non bioghist children
      children << child if keep_track_of_child
    end

    # if this is an innermost bioghist, and no subnotes have been made,
    # put all the markup into a note_text
    if nested_bioghists.empty? && @note.subnotes.empty?
      text_note = ASpaceImport::JSONModel(:note_text).new({
        'content' => bioghist_df.inner_html
      })
      @note.subnotes.push(text_note)
    end

    # if this is not an innermost bioghist, and no subnotes have been made,
    # dump all the non-bioghist children into a text note
    if !nested_bioghists.empty? && @note.subnotes.empty? && !children.empty?
      text_note = ASpaceImport::JSONModel(:note_text).new({
        'content' => ""
      })

      children.each do |node|
        # we use the <head> tag on the outermost node for the label
        next if outermost && node.name == 'head'
        xml = node.to_xml
        next if xml.strip.empty?
        text_note.content += xml
      end
      @note.subnotes.push(text_note) unless text_note.content.empty?
    end
    # now process all the nested bioghists
    while !nested_bioghists.empty?
      process_bioghist(nested_bioghists.shift, false)
    end
  end

  def extract_place(chronitem)
    chronitem.xpath("descendant::geogname").map {|g| g.inner_html }.join("\n")
  end

  def extract_chronitem_dates(chronitem)
    dates = {}
    chronitem.children.each do |c|
      case c.name
      when "datesingle"
        dates['date_singular'] = c.content
      when "daterange"
        dates['date_from'] = c.xpath('fromdate').text
        dates['date_to'] = c.xpath('todate').text
      end
    end
    return dates
  end

end
