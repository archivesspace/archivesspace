require 'java'

module MixedContentParser

  def self.parse(content, base_uri, opts = {} )
    opts[:pretty_print] ||= false

    return if content.nil?

    content.strip!
    content.chomp!

    return '' if content.empty?

    # create an empty document just to get an outputSettings object
    # (seems like the API falls down when we do this directly...)
    d = org.jsoup.Jsoup.parse("")
    d.outputSettings.prettyPrint(opts[:pretty_print])
    # self-close void elements (<br />, <img />) so the XML re-parse below keeps them empty
    d.outputSettings.syntax(Java::OrgJsoupNodes::Document::OutputSettings::Syntax.xml)

    # archon does things differently.....
    content.gsub!("\n\t", "\n\n")

    # turn <lb/> into the void <br/> up front: the HTML parser ignores the self-closing slash on
    # non-void elements, so <lb/> would otherwise swallow the text that follows it. <lb> is always
    # empty in EAD, so any closing </lb> is dropped. The lookahead keeps <lb-foo> or <lb:x> intact.
    content.gsub!(%r{<lb(?=[\s/>])[^<>]*>}i, '<br/>')
    content.gsub!(%r{</lb\s*>}i, '')

    # transform blocks of text seperated by line breaks into <p> wrapped blocks
    content = content.split("\n\n").inject("") { |c, n| c << "<p>#{n}</p>" } if opts[:wrap_blocks]

    safelist = org.jsoup.safety.Safelist.relaxed
                                        .addTags("emph", "lb", "title", "unitdate")
                                        .addAttributes("emph", "render")
                                        .addAttributes("title", "render")
                                        .addAttributes("unitdate", "render")

    cleaned_content = org.jsoup.Jsoup.clean(content, base_uri, safelist, d.outputSettings())

    document = org.jsoup.Jsoup.parse(cleaned_content, base_uri, org.jsoup.parser.Parser.xmlParser())
    document.outputSettings.escapeMode(Java::OrgJsoupNodes::Entities::EscapeMode.xhtml)
    document.outputSettings.prettyPrint(opts[:pretty_print])

    # replace lb with br
    document.select("lb").tagName("br")

    # tweak the emph tags
    [ "emph", "title", "unitdate"  ].each do |tag|
      document.select(tag).each do |emph|
        # make all emph's a span
        emph.tagName("span")

        # <emph> should render as <em> if there is no @render attribute. If there is, render as follows:
        if emph.attr("render").empty?
          emph.attr("class", "emph render-none")

        # render="nonproport": <code>
        elsif emph.attr("render") === "nonproport"
          emph.attr("class", "emph render-#{emph.attr("render")}")
          emph.tagName("code")
          emph.removeAttr("render")

        # set a class so CSS can style based on the render value
        else
          emph.attr("class", "emph render-#{emph.attr("render")}")
          emph.removeAttr("render")
        end
      end
    end
    document.toString()
  end

end
