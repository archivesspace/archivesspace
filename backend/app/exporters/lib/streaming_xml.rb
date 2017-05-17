module ASpaceExport
  class RawXMLHandler

    def initialize
      @fragments = {}
    end

    def <<(s)
      id = SecureRandom.hex
      @fragments[id] = s
      ":aspace_fragment_#{id}"
    end

    def substitute_fragments(xml_string)
      @fragments.each do |id, fragment|
        xml_string.gsub!(/:aspace_fragment_#{id}/, fragment)
        xml_string.gsub!(/[&]([^a])/, '&amp;\1')
      end

      xml_string
    end
  end


  class StreamHandler

    def initialize
      @sections = {}
      @depth = 0
    end


    def buffer(&block)
      id = SecureRandom.hex
      @sections[id] = block
      ":aspace_section_#{id}_"
    end

    def stream_out(doc, fragments, y, depth=0)
      xml_text = doc.to_xml(:encoding => 'utf-8')

      return if xml_text.empty?
      xml_text.force_encoding('utf-8')
      queue = xml_text.split(":aspace_section")

      xml_string = fragments.substitute_fragments(queue.shift)
      raise "Undereferenced Fragment: #{xml_string}" if xml_string =~ /:aspace_fragment/
      y << xml_string

      while queue.length > 0
        next_section = queue.shift
        next_id = next_section.slice!(/^_(\w+)_/).gsub(/_/, '')
        next_fragments = RawXMLHandler.new
        doc_frag = Nokogiri::XML::DocumentFragment.new(Nokogiri::XML::Document.new)
        Nokogiri::XML::Builder.with(doc_frag) do |xml|
          @sections[next_id].call(xml, next_fragments)
        end
        stream_out(doc_frag, next_fragments, y, depth + 1)

        if next_section && !next_section.empty?
          y << fragments.substitute_fragments(next_section)
        end
      end
    end
  end

end
