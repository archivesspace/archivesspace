require 'java'

module MixedContentParser

  def self.parse(content, base_uri, opts = {} )
    content.strip!
    content.chomp!

    # transform blocks of text seperated by line breaks into <p> wrapped blocks
    content = content.split("\n\n").inject("") { |c,n| c << "<p>#{n}</p>"  } if opts[:wrap_blocks]

    cleaned_content = org.jsoup.Jsoup.clean(content, org.jsoup.safety.Whitelist.relaxed.addTags("emph", "lb").addAttributes("emph", "render"))


    document = org.jsoup.Jsoup.parse(cleaned_content, base_uri, org.jsoup.parser.Parser.xmlParser())

    # replace lb with br
    document.select("lb").tagName("br")

    # tweak the emph tags
    [ "emph", "title", "unitdate"  ].each do |tag| 
      document.select(tag).each do | emph |
        # make all emph's a span
        emph.tagName("span")

        # <emph> should render as <em> if there is no @render attribute. If there is, render as follows:
        if emph.attr("render").blank?
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
