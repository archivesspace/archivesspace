require_relative '../../common/mixed_content_parser'

Dir.glob(File.join(File.dirname(__FILE__), '../', '../', 'common', 'lib', "*.jar")).each do |file|
  require file
end


describe 'MixedContentParser' do

  it "can convert paragraph breaks to paragraph tags", :skip_db_open do
    text = "foo\n\nbar"

    converted = MixedContentParser.parse(text, "http://example.com", {:wrap_blocks => true})

    expect(converted.gsub(/\s/, "")).to eq("<p>foo</p><p>bar</p>")
  end


  it "won't pretty print output by default", :skip_db_open do
    text = "What the & 'heck' <emph>ok</emph>?"

    converted = MixedContentParser.parse(text, "http://example.com", {:wrap_blocks => false})

    expect(converted).to eq("What the &amp; 'heck' <span class=\"emph render-none\">ok</span>?");
  end

  it "converts emph element correctly", :skip_db_open do
    text = "<emph render='italic'>emph text</emph>"

    converted = MixedContentParser.parse(text, "http://example.com", {:wrap_blocks => false})

    expect(converted).to eq("<span class=\"emph render-italic\">emph text</span>");
  end


  it "converts title element correctly", :skip_db_open do
    text = "<title render='italic' xlink:type='simple'>title text</title>"

    converted = MixedContentParser.parse(text, "http://example.com", {:wrap_blocks => false})

    expect(converted).to eq("<span class=\"emph render-italic\">title text</span>");
  end

  it "converts lb elements to br without swallowing the following text", :skip_db_open do
    ["one<lb/>two", "one<lb />two", "one<lb></lb>two", "one<LB>two", "one<lb>two</lb>"].each do |text|
      converted = MixedContentParser.parse(text, "http://example.com", {:wrap_blocks => false})

      expect(converted).to eq("one<br />two"), "for #{text.inspect}"
    end
  end


  it "does not treat elements whose names start with lb as lb", :skip_db_open do
    converted = MixedContentParser.parse("one<lb-foo>two</lb-foo>", "http://example.com", {:wrap_blocks => false})

    expect(converted).not_to include("<br")
    expect(converted).to include("two")
  end


  it "keeps self-closed elements empty instead of swallowing the following text", :skip_db_open do
    {
      "one <emph render=\"bold\"/> two" => "one <span class=\"emph render-bold\"></span> two",
      "one <unitdate normal=\"1900\" /> two" => "one <span class=\"emph render-none\"></span> two",
      "one <a href=\"http://example.com/x\"/> two" => "one <a href=\"http://example.com/x\"></a> two",
      "one <span/> two" => "one <span></span> two",
      "one <p/> two" => "one <p></p> two",
      # the HTML parser reads everything after <title> as text until </title>
      "one <title render=\"italic\"/> two <emph>three</emph>" =>
        "one <span class=\"emph render-italic\"></span> two <span class=\"emph render-none\">three</span>"
    }.each do |text, expected|
      converted = MixedContentParser.parse(text, "http://example.com", {:wrap_blocks => false})

      expect(converted).to eq(expected), "for #{text.inspect}"
    end
  end


  it "does not write non-void elements as self-closing", :skip_db_open do
    converted = MixedContentParser.parse("one<p/><p>two</p>", "http://example.com", {:wrap_blocks => false})

    expect(converted).to eq("one<p></p><p>two</p>")
  end


  it "does not modify the string it is given", :skip_db_open do
    text = "  one<lb/>two\n\tthree  "
    original = text.dup

    MixedContentParser.parse(text, "http://example.com", {:wrap_blocks => true})

    expect(text).to eq(original)
  end


  it "accepts frozen strings", :skip_db_open do
    converted = MixedContentParser.parse(" one<lb/>two ".freeze, "http://example.com", {:wrap_blocks => false})

    expect(converted).to eq("one<br />two")
  end


  it "keeps pretty_print per call", :skip_db_open do
    text = "foo\n\nbar"

    pretty = MixedContentParser.parse(text, "http://example.com", {:wrap_blocks => true, :pretty_print => true})
    compact = MixedContentParser.parse(text, "http://example.com", {:wrap_blocks => true})

    expect(compact).to eq("<p>foo</p><p>bar</p>")
    expect(pretty).to include("\n")
  end

end
