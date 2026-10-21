require 'java'

module MixedContentParser

  def self.safelist
    @safelist ||= org.jsoup.safety.Safelist.relaxed
                                           .addTags("emph", "title", "unitdate")
                                           .addAttributes("emph", "render")
                                           .addAttributes("title", "render")
                                           .addAttributes("unitdate", "render")
  end

  # let every tag self-close as in XML
  def self.html_parser
    tag_set = org.jsoup.parser.TagSet.Html.onNewTag do |tag|
      tag.set(org.jsoup.parser.Tag.SelfClose) unless tag.is(org.jsoup.parser.Tag.Void)
    end

    org.jsoup.parser.Parser.htmlParser.tagSet(tag_set)
  end

  # Jsoup.clean, but parsing with html_parser
  def self.clean(content, base_uri, output_settings)
    dirty = org.jsoup.nodes.Document.createShell(base_uri)
    dirty.body.appendChildren(html_parser.parseFragmentInput(content, dirty.body, base_uri))

    # forget the self-closing, or the output would be <span />, which browsers do not close either
    dirty.body.getAllElements.each do |el|
      next if el.tag.is(org.jsoup.parser.Tag.Void)

      el.tag.clear(org.jsoup.parser.Tag.SelfClose | org.jsoup.parser.Tag.SeenSelfClose)
    end

    clean = org.jsoup.safety.Cleaner.new(safelist).clean(dirty)
    clean.outputSettings(output_settings)
    clean.body.html
  end

  def self.parse(content, base_uri, opts = {} )
    opts[:pretty_print] ||= false

    return if content.nil?

    # never modify the caller's string: callers pass record fields straight from the JSON
    content = content.strip

    return '' if content.empty?

    output_settings = Java::OrgJsoupNodes::Document::OutputSettings.new
    output_settings.prettyPrint(opts[:pretty_print])
    # self-close void elements (<br />, <img />) so the XML re-parse below keeps them empty
    output_settings.syntax(Java::OrgJsoupNodes::Document::OutputSettings::Syntax.xml)

    # archon does things differently.....
    content = content.gsub("\n\t", "\n\n")

    # turn <lb/> into the void <br/> up front, so it renders as a single line break. <lb> is always
    # empty in EAD, so any closing </lb> is dropped. The lookahead keeps <lb-foo> or <lb:x> intact.
    content = content.gsub(%r{<lb(?=[\s/>])[^<>]*>}i, '<br/>')
    content = content.gsub(%r{</lb\s*>}i, '')

    # transform blocks of text seperated by line breaks into <p> wrapped blocks
    content = content.split("\n\n").inject("") { |c, n| c << "<p>#{n}</p>" } if opts[:wrap_blocks]

    cleaned_content = clean(content, base_uri, output_settings)

    document = org.jsoup.Jsoup.parse(cleaned_content, base_uri, org.jsoup.parser.Parser.xmlParser())
    document.outputSettings.escapeMode(Java::OrgJsoupNodes::Entities::EscapeMode.xhtml)
    document.outputSettings.prettyPrint(opts[:pretty_print])

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
