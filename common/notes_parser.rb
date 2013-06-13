require 'java'

require Rails.root.join('..', 'common', 'lib', 'jsoup-1.7.2.jar')

module NotesParser

  def self.parse(note, base_uri)
    cleaned_note = org.jsoup.Jsoup.clean(note, org.jsoup.safety.Whitelist.relaxed.addTags("emph", "lb").addAttributes("emph", "render"))

    document = org.jsoup.Jsoup.parse(cleaned_note, base_uri, org.jsoup.parser.Parser.xmlParser())

    # replace lb with br
    document.select("lb").tagName("br")

    # tweak the emph tags
    document.select("emph").each do | emph |
      # <emph> should render as <em> if there is no @render attribute. If there is, render as follows:
      if emph.attr("render").blank?
        emph.tagName("em")

        # render="bolditalic: <strong><em>
      elsif emph.attr("render") === "bolditalic"
        emph.tagName("em")
        emph.wrap("<strong></strong>")

        # render="bold" (or contains "bold"): <strong>
      elsif emph.attr("render").include?("bold")
        emph.tagName("strong")

        # render="italic": <em>
      elsif emph.attr("render") === "italic"
        emph.tagName("em")

        # render="super": <sup>
      elsif emph.attr("render") === "super"
        emph.tagName("sup")

        # render="sub": <sub>
      elsif emph.attr("render") === "sub"
        emph.tagName("sub")

        # render="underline": (style as CSS with underline)
      elsif emph.attr("render") === "underline"
        emph.tagName("span").attr("class", "underlined")

        # render="nonproport": <code>
      elsif emph.attr("render") === "nonproport"
        emph.tagName("code")

        # just make it an em
      else
        emph.tagName("em")
      end
    end

    document.toString()
  end

end