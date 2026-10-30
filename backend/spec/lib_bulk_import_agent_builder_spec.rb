require "spec_helper"
require_relative "../app/lib/bulk_import/agent_builder"

describe AgentBuilder do
  def controlled_value_resolver
    calls = []
    lists = {
      "name_person_name_order" => { "Direct" => "direct", "direct" => "direct", "inverted" => "inverted" },
      "name_source" => { "LCNAF" => "naf", "naf" => "naf" },
      "agent_contact_salutation" => { "Mr" => "mr", "mr" => "mr" },
      "telephone_number_type" => { "home" => "home", "fax" => "fax" },
    }
    resolver = lambda do |list_name, submitted|
      raise ArgumentError, "unexpected controlled-value list #{list_name}" unless lists.key?(list_name)

      calls << [list_name, submitted]
      lists[list_name][submitted]
    end
    resolver.define_singleton_method(:calls) { calls }
    resolver
  end

  def agent_attributes(overrides = {})
    name_overrides = overrides.delete(:name) || {}
    {
      :agent_type => "person",
      :name => { :primary_name => "Orwell", :name_order => "direct" }.merge(name_overrides),
    }.merge(overrides)
  end

  def builder_for(resolver: controlled_value_resolver, **overrides)
    described_class.new(
      :attributes => agent_attributes(overrides),
      :controlled_value_resolver => resolver
    )
  end

  def error_for(builder, attribute)
    builder.errors.find { |error| error[:attribute] == attribute }
  end

  describe "a valid person" do
    it "returns a person Agent hash with one Name and the canonical Name Order" do
      resolver = controlled_value_resolver
      builder = builder_for(:resolver => resolver, :name => { :name_order => "Direct" })

      expect(builder.errors).to eq([])
      expect(resolver.calls).to eq([["name_person_name_order", "Direct"]])
      expect(builder.to_h).to eq(
        "jsonmodel_type" => "agent_person",
        "names" => [
          {
            "jsonmodel_type" => "name_person",
            "primary_name" => "Orwell",
            "name_order" => "direct",
          },
        ]
      )
    end
  end

  describe "minimum person data" do
    [
      [:agent_type, { :agent_type => nil }],
      [:primary_name, { :name => { :primary_name => nil } }],
      [:name_order, { :name => { :name_order => "" } }],
    ].each do |attribute, overrides|
      it "requires #{attribute}" do
        builder = builder_for(**overrides)

        expect(error_for(builder, attribute)).to include(:code => :required)
      end
    end

    it "reports every missing field, not only the first" do
      builder = builder_for(:name => { :primary_name => nil, :name_order => nil })

      expect(builder.errors.map { |error| error[:attribute] }).to contain_exactly(:primary_name, :name_order)
    end

    it "rejects an unrecognized Name Order and keeps the submitted value" do
      builder = builder_for(:name => { :name_order => "sideways" })

      expect(error_for(builder, :name_order)).to include(:code => :invalid, :record => :name, :value => "sideways")
    end

    it "does not consult the controlled-value list for a blank Name Order" do
      resolver = controlled_value_resolver
      builder_for(:resolver => resolver, :name => { :name_order => nil })

      expect(resolver.calls).to eq([])
    end
  end

  describe "a valid family" do
    it "maps the primary name to the family Name's family_name" do
      builder = builder_for(:agent_type => "family", :name => { :primary_name => "Smith", :prefix => "The", :name_order => nil })

      expect(builder.errors).to eq([])
      expect(builder.to_h).to eq(
        "jsonmodel_type" => "agent_family",
        "names" => [{ "jsonmodel_type" => "name_family", "family_name" => "Smith", "prefix" => "The" }]
      )
    end
  end

  describe "a valid corporate entity" do
    it "keeps the primary name and the subordinate names" do
      builder = builder_for(
        :agent_type => "corporate_entity",
        :name => { :primary_name => "Acme", :subordinate_name_1 => "Research", :subordinate_name_2 => "Labs", :number => "7", :name_order => nil }
      )

      expect(builder.errors).to eq([])
      expect(builder.to_h["names"]).to eq(
        [{ "jsonmodel_type" => "name_corporate_entity", "primary_name" => "Acme", "subordinate_name_1" => "Research", "subordinate_name_2" => "Labs", "number" => "7" }]
      )
    end
  end

  describe "minimum family and corporate entity data" do
    %w[family corporate_entity].each do |agent_type|
      it "requires a primary name for #{agent_type}" do
        builder = builder_for(:agent_type => agent_type, :name => { :primary_name => nil, :name_order => nil })

        expect(builder.errors).to eq([{ :code => :required, :record => :name, :attribute => :primary_name, :value => nil }])
      end
    end
  end

  describe "fields incompatible with the Agent type" do
    [
      ["person", :subordinate_name_1],
      ["family", :name_order],
      ["family", :title],
      ["family", :number],
      ["corporate_entity", :name_order],
      ["corporate_entity", :prefix],
    ].each do |agent_type, attribute|
      it "reports #{attribute} on #{agent_type} and keeps the submitted value" do
        name = { :name_order => (agent_type == "person" ? "direct" : nil), attribute => "populated" }
        builder = builder_for(:agent_type => agent_type, :name => name)

        expect(error_for(builder, attribute)).to eq(
          :code => :incompatible, :record => :name, :attribute => attribute, :value => "populated"
        )
      end
    end

    it "does not report a blank incompatible field" do
      builder = builder_for(:agent_type => "family", :name => { :primary_name => "Smith", :title => "", :name_order => nil })

      expect(builder.errors).to eq([])
    end

    it "reports every incompatible field, not only the first" do
      builder = builder_for(:agent_type => "family", :name => { :primary_name => "Smith", :title => "Dr", :suffix => "Jr", :name_order => nil })

      expect(builder.errors.map { |error| error[:attribute] }).to contain_exactly(:title, :suffix)
    end
  end

  describe "Sort Name" do
    it "preserves an explicit Sort Name and disables automatic generation" do
      builder = builder_for(:name => { :sort_name => "Orwell, G." })

      expect(builder.to_h["names"][0]).to include("sort_name" => "Orwell, G.", "sort_name_auto_generate" => false)
    end

    it "leaves generation to the model when Sort Name is blank" do
      builder = builder_for(:name => { :sort_name => "" })

      expect(builder.to_h["names"][0]).not_to include("sort_name", "sort_name_auto_generate")
    end
  end

  describe "controlled-value Name fields" do
    it "stores the canonical value for a recognized Source" do
      resolver = controlled_value_resolver
      builder = builder_for(:resolver => resolver, :name => { :source => "LCNAF" })

      expect(builder.to_h["names"][0]["source"]).to eq("naf")
      expect(resolver.calls).to include(["name_source", "LCNAF"])
    end

    it "rejects an unrecognized Source and keeps the submitted value" do
      builder = builder_for(:name => { :source => "nowhere" })

      expect(error_for(builder, :source)).to include(:code => :invalid, :record => :name, :value => "nowhere")
    end
  end

  describe "unsupported Agent types" do
    it "reports a software Agent as unsupported without checking its Name" do
      builder = builder_for(:agent_type => "software", :name => { :name_order => nil })

      expect(builder.errors).to eq([{ :code => :unsupported, :record => nil, :attribute => :agent_type, :value => "software" }])
    end

    it "reports a prefixed Agent type as unsupported" do
      builder = builder_for(:agent_type => "agent_person")

      expect(builder.errors).to eq([{ :code => :unsupported, :record => nil, :attribute => :agent_type, :value => "agent_person" }])
    end
  end

  describe "Agent type normalization" do
    it "accepts a mixed-case or padded Agent type" do
      builder = builder_for(:agent_type => " Person ")

      expect(builder.errors).to eq([])
      expect(builder.to_h["jsonmodel_type"]).to eq("agent_person")
    end
  end

  describe "a Contact" do
    it "is omitted when no contact, telephone or fax value is populated" do
      builder = builder_for(:contact => { :name => "", :telephone => { :number => nil, :ext => "" }, :fax => { :number => nil } })

      expect(builder.errors).to eq([])
      expect(builder.to_h).not_to include("agent_contacts")
    end

    it "keeps the canonical salutation and the plain values" do
      resolver = controlled_value_resolver
      builder = builder_for(:resolver => resolver, :contact => { :name => "Front Desk", :salutation => "Mr", :city => "Springfield" })

      expect(builder.to_h["agent_contacts"]).to eq(
        [{ "jsonmodel_type" => "agent_contact", "name" => "Front Desk", "salutation" => "mr", "city" => "Springfield" }]
      )
      expect(resolver.calls).to include(["agent_contact_salutation", "Mr"])
    end

    it "requires a name when only a fax number is populated" do
      builder = builder_for(:contact => { :fax => { :number => "555-0199" } })

      expect(builder.errors).to eq([{ :code => :required, :record => :contact, :attribute => :name, :value => nil }])
    end

    it "rejects an unrecognized salutation and keeps the submitted value" do
      builder = builder_for(:contact => { :name => "Front Desk", :salutation => "your-grace" })

      expect(error_for(builder, :salutation)).to include(:code => :invalid, :record => :contact, :value => "your-grace")
    end
  end

  describe "telephone and fax" do
    def telephones_for(contact)
      builder_for(:contact => { :name => "Front Desk" }.merge(contact)).to_h["agent_contacts"][0]["telephones"]
    end

    it "stores the ordinary telephone as a home number with its extension" do
      expect(telephones_for(:telephone => { :number => "555-0100", :ext => "42" })).to eq(
        [{ "jsonmodel_type" => "telephone", "number" => "555-0100", "ext" => "42", "number_type" => "home" }]
      )
    end

    it "stores a fax number with the fax number type" do
      expect(telephones_for(:fax => { :number => "555-0199" })).to eq(
        [{ "jsonmodel_type" => "telephone", "number" => "555-0199", "number_type" => "fax" }]
      )
    end

    it "keeps both when both are supplied" do
      numbers = telephones_for(:telephone => { :number => "555-0100" }, :fax => { :number => "555-0199" })

      expect(numbers.map { |phone| phone["number_type"] }).to contain_exactly("home", "fax")
    end

    it "rejects an extension supplied without a number" do
      builder = builder_for(:contact => { :name => "Front Desk", :telephone => { :ext => "42" } })

      expect(builder.errors).to eq([{ :code => :required, :record => :contact, :nested => :telephone, :attribute => :number, :value => nil }])
    end

    it "reports a nested record that has no matching schema record or number type" do
      builder = builder_for(:contact => { :name => "Front Desk", :pager => { :number => "555-0111" } })

      expect(builder.errors).to eq([{ :code => :incompatible, :record => :contact, :nested => :pager, :attribute => :number, :value => "555-0111" }])
    end
  end

  describe "a biographical/historical note" do
    it "is omitted when content and citation are blank" do
      builder = builder_for(:note => { :content => "", :citation => nil })

      expect(builder.to_h).not_to include("notes")
    end

    it "builds a text subnote and a citation subnote with the citation as a list" do
      builder = builder_for(:note => { :content => "Born 1903.", :citation => "Crick, 1980" })

      expect(builder.to_h["notes"]).to eq(
        [{
          "jsonmodel_type" => "note_bioghist",
          "subnotes" => [
            { "jsonmodel_type" => "note_text", "content" => "Born 1903." },
            { "jsonmodel_type" => "note_citation", "content" => ["Crick, 1980"] },
          ],
        }]
      )
    end

    it "builds a note from either field on its own" do
      content_only = builder_for(:note => { :content => "Born 1903." }).to_h["notes"][0]["subnotes"]
      citation_only = builder_for(:note => { :citation => "Crick, 1980" }).to_h["notes"][0]["subnotes"]

      expect(content_only.map { |subnote| subnote["jsonmodel_type"] }).to eq(%w[note_text])
      expect(citation_only.map { |subnote| subnote["jsonmodel_type"] }).to eq(%w[note_citation])
    end

    it "reports a note attribute that is not an allowed subnote type" do
      builder = builder_for(:note => { :content => "Born 1903.", :nonsense => "x" })

      expect(builder.errors).to eq([{ :code => :incompatible, :record => :note, :attribute => :nonsense, :value => "x" }])
    end
  end

  describe "publication" do
    it "omits publish when it is blank so the model applies the preference" do
      expect(builder_for(:publish => "").to_h).not_to include("publish")
    end

    it "accepts the strict boolean tokens in any case" do
      expect(builder_for(:publish => " Yes ").to_h["publish"]).to eq(true)
      expect(builder_for(:publish => "f").to_h["publish"]).to eq(false)
    end

    it "rejects an unrecognized token and keeps the submitted value" do
      builder = builder_for(:publish => "maybe")

      expect(builder.errors).to eq([{ :code => :invalid, :record => nil, :attribute => :publish, :value => "maybe" }])
    end
  end

  describe "#to_h" do
    it "refuses to build when the request has errors" do
      builder = builder_for(:name => { :primary_name => nil })

      expect { builder.to_h }.to raise_error(ArgumentError)
    end
  end

  describe "#supplied_values" do
    it "leaves out the values the builder derives rather than copies from a column" do
      builder = builder_for(
        :name => { :sort_name => "Orwell, G." },
        :contact => { :name => "Front Desk", :telephone => { :number => "555-0100" }, :fax => { :number => "555-0199" } }
      )

      supplied = builder.supplied_values
      expect(supplied["names"][0]).to include("sort_name" => "Orwell, G.")
      expect(supplied["names"][0]).not_to include("sort_name_auto_generate")
      expect(supplied["agent_contacts"][0]["telephones"]).to eq(
        [
          { "jsonmodel_type" => "telephone", "number" => "555-0100" },
          { "jsonmodel_type" => "telephone", "number" => "555-0199", "number_type" => "fax" },
        ]
      )
    end

    it "refuses to build when the request has errors" do
      builder = builder_for(:name => { :primary_name => nil })

      expect { builder.supplied_values }.to raise_error(ArgumentError)
    end
  end
end
