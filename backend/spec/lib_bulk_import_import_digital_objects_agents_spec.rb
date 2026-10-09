require "spec_helper"
require_relative "../app/lib/bulk_import/import_digital_objects.rb"
require_relative "lib_bulk_import_import_digital_objects_shared_context"

describe "Import Digital Objects Agents" do
  include_context "digital object importer harness"

  TEMPLATES_DIR = File.join(File.dirname(__FILE__), "../", "../", "frontend", "public", "bulk_import_templates") unless defined?(TEMPLATES_DIR)

  def run_agent_import(row_overrides, validate_only = false)
    csv_data = CSV.read(File.join(TEMPLATES_DIR, "bulk_import_DO_template.csv"))
    columns = csv_data[0].dup
    column_explanations = csv_data[1].dup
    row_overrides.keys.map { |key| key[/\Aagent_(\d+)_/, 1] }.compact.uniq.each do |index|
      next if columns.any? { |column| column.to_s.start_with?("agent_#{index}_") }

      extra = family_headers_at(csv_data[0], "agent", index)
      columns += extra
      column_explanations += extra.map { "Agent(#{index})" }
    end

    row = {}
    columns.each { |column| row[column] = nil }
    row["res_uri"] = @resource.uri
    row["ao_uri"] = @archival_object.uri
    row["digital_object_title"] = "Digital Object Title #{@now}"
    row_overrides.each { |key, value| row[key] = value }

    import_digital_object_csv(columns, column_explanations, row, validate_only: validate_only)
  end

  def person_group(overrides = {})
    {
      "agent_1_agent_type" => "agent_person",
      "agent_1_agent_name_1_primary_name" => "Created Person #{@now}",
      "agent_1_agent_name_1_name_order" => "direct",
    }.merge(overrides)
  end

  def imported_digital_object
    ::DigitalObject.to_jsonmodel(
      DigitalObject.where(:title => "Digital Object Title #{@now}").first.id
    )
  end

  def linked_agent_records(digital_object)
    digital_object.linked_agents.map { |link| JSONModel(:agent_person).find_by_uri(link["ref"]) }
  end

  context "repeatable groups" do
    it "processes groups in numeric order, not header or text order" do
      report = run_agent_import(
        "agent_10_agent_type" => "agent_person",
        "agent_10_header" => "Person ten #{@now}",
        "agent_3_agent_type" => "agent_person",
        "agent_3_header" => "Person three #{@now}"
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])

      creation_order = imported_digital_object.linked_agents
        .sort_by { |link| link["ref"][/\d+\z/].to_i }
        .map { |link| JSONModel(:agent_person).find_by_uri(link["ref"]).title }
      expect(creation_order).to eq(["Person three #{@now}", "Person ten #{@now}"])
    end
  end

  context "legacy Agent creation" do
    it "publishes an Agent created from a Header String" do
      report = run_agent_import(
        "agent_1_agent_type" => "agent_person",
        "agent_1_header" => "Minimal Person #{@now}"
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])
      expect(linked_agent_records(imported_digital_object).map(&:publish)).to eq([true])
    end

    it "creates an unpublished placeholder Agent for an unresolved numeric ID" do
      report = run_agent_import(
        "agent_1_agent_type" => "agent_person",
        "agent_1_record_id" => "987654321"
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])
      agents = linked_agent_records(imported_digital_object)
      expect(agents.length).to eq(1)
      expect(agents[0].publish).to be_falsey
    end

    it "records an Agent created from a Header String among the job's created records" do
      allow(ImportDigitalObjects).to receive(:new).and_wrap_original do |original, *args|
        @importer = original.call(*args)
      end

      report = run_agent_import(
        "agent_1_agent_type" => "agent_person",
        "agent_1_header" => "Recorded Person #{@now}"
      )

      expect(report.rows[0].errors).to eq([])
      agent_uri = imported_digital_object.linked_agents.first["ref"]
      expect(@importer.record_uris).to include(agent_uri)
    end

    it "records a placeholder Agent created for an unresolved numeric ID among the job's created records" do
      allow(ImportDigitalObjects).to receive(:new).and_wrap_original do |original, *args|
        @importer = original.call(*args)
      end

      report = run_agent_import(
        "agent_1_agent_type" => "agent_person",
        "agent_1_record_id" => "987654321"
      )

      expect(report.rows[0].errors).to eq([])
      agent_uri = imported_digital_object.linked_agents.first["ref"]
      expect(@importer.record_uris).to include(agent_uri)
    end

    it "records a disambiguation Agent among the job's created records" do
      allow(ImportDigitalObjects).to receive(:new).and_wrap_original do |original, *args|
        @importer = original.call(*args)
      end
      header = "Ambiguous Person #{@now}"
      match = { "title" => header, "json" => "{}" }
      allow(Search).to receive(:search).and_wrap_original do |original, params, *rest|
        if params[:q].to_s.include?(header)
          { "total_hits" => 2, "results" => [match, match] }
        else
          original.call(params, *rest)
        end
      end

      report = run_agent_import(
        "agent_1_agent_type" => "agent_person",
        "agent_1_header" => header
      )

      expect(report.rows[0].errors).to eq([])
      agent_uri = imported_digital_object.linked_agents.first["ref"]
      expect(JSONModel(:agent_person).find_by_uri(agent_uri).title).to eq("#{header} DISAMBIGUATE ME!")
      expect(@importer.record_uris).to include(agent_uri)
    end
  end

  context "family Agent creation" do
    it "creates a family Agent from its primary name and links it" do
      original_count = AgentFamily.count

      report = run_agent_import(
        "agent_1_agent_type" => "agent_family",
        "agent_1_agent_name_1_primary_name" => "Created Family #{@now}"
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])
      expect(AgentFamily.count).to eq(original_count + 1)
      links = imported_digital_object.linked_agents
      expect(links.map { |link| link["role"] }).to eq(["creator"])
      family = JSONModel(:agent_family).find_by_uri(links.first["ref"])
      expect(family.names.map { |name| name["family_name"] }).to eq(["Created Family #{@now}"])
    end

    it "reports a person-only field on a family, creating and linking nothing" do
      original_count = AgentFamily.count

      report = run_agent_import(
        "agent_1_agent_type" => "agent_family",
        "agent_1_agent_name_1_primary_name" => "Created Family #{@now}",
        "agent_1_agent_name_1_title" => "Dr"
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.join(" ")).to include("agent_1_agent_name_1_title", "agent_family")
      expect(AgentFamily.count).to eq(original_count)
      expect(imported_digital_object.linked_agents).to eq([])
    end
  end

  context "corporate entity Agent creation" do
    it "creates a corporate entity with its subordinate names and explicit Sort Name" do
      original_count = AgentCorporateEntity.count

      report = run_agent_import(
        "agent_1_agent_type" => "agent_corporate_entity",
        "agent_1_agent_name_1_primary_name" => "Created Corp #{@now}",
        "agent_1_agent_name_1_subordinate_name_1" => "Research",
        "agent_1_agent_name_1_subordinate_name_2" => "Labs",
        "agent_1_agent_name_1_sort_name" => "Explicit Sort #{@now}"
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])
      expect(AgentCorporateEntity.count).to eq(original_count + 1)
      links = imported_digital_object.linked_agents
      corporate = JSONModel(:agent_corporate_entity).find_by_uri(links.first["ref"])
      expect(corporate.names[0]).to include(
        "primary_name" => "Created Corp #{@now}",
        "subordinate_name_1" => "Research",
        "subordinate_name_2" => "Labs",
        "sort_name" => "Explicit Sort #{@now}",
        "sort_name_auto_generate" => false
      )
    end
  end

  context "person Agent creation" do
    it "creates a person Agent from its name fields and links it" do
      original_count = AgentPerson.count

      report = run_agent_import(
        "agent_1_agent_type" => "agent_person",
        "agent_1_agent_name_1_primary_name" => "Created Person #{@now}",
        "agent_1_agent_name_1_name_order" => "direct"
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])
      expect(AgentPerson.count).to eq(original_count + 1)
      agents = linked_agent_records(imported_digital_object)
      expect(agents.map(&:title)).to eq(["Created Person #{@now}"])
      expect(imported_digital_object.linked_agents.map { |link| link["role"] }).to eq(["creator"])
    end

    it "records the created Agent among the job's created records" do
      allow(ImportDigitalObjects).to receive(:new).and_wrap_original do |original, *args|
        @importer = original.call(*args)
      end

      report = run_agent_import(person_group)

      expect(report.rows[0].errors).to eq([])
      agent_uri = imported_digital_object.linked_agents.first["ref"]
      expect(@importer.record_uris).to include(agent_uri)
    end

    it "records no created Agent in validate-only mode" do
      allow(ImportDigitalObjects).to receive(:new).and_wrap_original do |original, *args|
        @importer = original.call(*args)
      end

      run_agent_import(person_group, true)

      expect(@importer.record_uris).to eq([])
    end

    it "preserves an explicit role and relator on the link" do
      report = run_agent_import(person_group("agent_1_role" => "source", "agent_1_relator" => "aut"))

      expect(report.rows[0].errors).to eq([])
      link = imported_digital_object.linked_agents.first
      expect([link["role"], link["relator"]]).to eq(%w[source aut])
    end

    it "reports a missing primary name by its uploaded column and imports the Digital Object without an Agent" do
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_agent_name_1_primary_name" => nil))

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.join(" ")).to include("agent_1_agent_name_1_primary_name")
      expect(AgentPerson.count).to eq(original_count)
      expect(imported_digital_object.linked_agents).to eq([])
    end

    it "reports a missing Agent type by its uploaded column and imports the Digital Object without an Agent" do
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_agent_type" => nil))

      expect(report.rows[0].errors.join(" ")).to include("agent_1_agent_type")
      expect(AgentPerson.count).to eq(original_count)
      expect(imported_digital_object.linked_agents).to eq([])
    end

    it "reports a missing Name Order by its uploaded column and imports the Digital Object without an Agent" do
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_agent_name_1_name_order" => nil))

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.join(" ")).to include("agent_1_agent_name_1_name_order")
      expect(AgentPerson.count).to eq(original_count)
      expect(imported_digital_object.linked_agents).to eq([])
    end

    it "reports an unrecognized Name Order by its uploaded column and imports the Digital Object without an Agent" do
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_agent_name_1_name_order" => "sideways"))

      expect(report.rows[0].errors.join(" ")).to include("agent_1_agent_name_1_name_order", "sideways")
      expect(AgentPerson.count).to eq(original_count)
      expect(imported_digital_object.linked_agents).to eq([])
    end

    it "reports an unsupported Agent type and imports the Digital Object without an Agent" do
      original_count = AgentFamily.count

      report = run_agent_import(person_group("agent_1_agent_type" => "agent_family"))

      expect(report.rows[0].errors.join(" ")).to include("agent_family")
      expect(AgentFamily.count).to eq(original_count)
      expect(imported_digital_object.linked_agents).to eq([])
    end

    it "reports an invalid role and imports the Digital Object without an Agent" do
      original_count = AgentPerson.count
      bad_role = "not-a-role-#{@now}"

      report = run_agent_import(person_group("agent_1_role" => bad_role))

      expect(report.rows[0].errors.join(" ")).to include(bad_role)
      expect(AgentPerson.count).to eq(original_count)
      expect(imported_digital_object.linked_agents).to eq([])
    end

    it "creates no Agent and no Digital Object in validate-only mode" do
      original_count = AgentPerson.count

      report = run_agent_import(person_group, true)

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])
      expect(AgentPerson.count).to eq(original_count)
      expect(DigitalObject.where(:title => "Digital Object Title #{@now}").count).to eq(0)
    end

    it "reports an Agent that fails schema validation and imports the Digital Object without an Agent" do
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_agent_name_1_primary_name" => "x" * 256))

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.join(" ")).to include("primary_name")
      expect(AgentPerson.count).to eq(original_count)
      expect(imported_digital_object.linked_agents).to eq([])
    end
  end

  context "creating an Agent with contact, telephone, fax, note and publication" do
    it "saves the Contact, nested telephone and fax, biographical note and explicit publish value" do
      report = run_agent_import(
        person_group(
          "agent_1_publish" => "yes",
          "agent_1_agent_contact_1_name" => "Contact Name #{@now}",
          "agent_1_agent_contact_1_salutation" => "mr",
          "agent_1_agent_contact_1_address_1" => "1 Main Street",
          "agent_1_agent_contact_1_city" => "Springfield",
          "agent_1_agent_contact_1_region" => "IL",
          "agent_1_agent_contact_1_country" => "US",
          "agent_1_agent_contact_1_post_code" => "62701",
          "agent_1_agent_contact_1_email" => "contact@example.org",
          "agent_1_agent_contact_1_telephone_1_number" => "555-0100",
          "agent_1_agent_contact_1_telephone_1_ext" => "42",
          "agent_1_agent_contact_1_fax_1_number" => "555-0199",
          "agent_1_note_1_content" => "Biography text #{@now}",
          "agent_1_note_1_citation" => "Citation text #{@now}"
        )
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])

      agent = linked_agent_records(imported_digital_object).first
      expect(agent.publish).to eq(true)

      contact = agent.agent_contacts.first
      expect(contact).to include(
        "name" => "Contact Name #{@now}",
        "salutation" => "mr",
        "address_1" => "1 Main Street",
        "city" => "Springfield",
        "region" => "IL",
        "country" => "US",
        "post_code" => "62701",
        "email" => "contact@example.org"
      )
      telephones = contact["telephones"].map { |phone| phone.slice("number_type", "number", "ext") }
      expect(telephones).to contain_exactly(
        { "number_type" => "home", "number" => "555-0100", "ext" => "42" },
        { "number_type" => "fax", "number" => "555-0199" }
      )

      subnotes = agent.notes.first["subnotes"]
      expect(subnotes.map { |subnote| subnote["jsonmodel_type"] }).to eq(%w[note_text note_citation])
      expect(subnotes[0]["content"]).to eq("Biography text #{@now}")
      expect(subnotes[1]["content"]).to eq(["Citation text #{@now}"])
    end
  end

  context "contact, telephone, fax, note and publication partitions" do
    def contact_group(overrides = {})
      person_group({ "agent_1_agent_contact_1_name" => "Contact Name #{@now}" }.merge(overrides))
    end

    def expect_no_agent_created(report, *field_codes)
      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.join(" ")).to include(*field_codes)
      expect(AgentPerson.count).to eq(@original_count)
      expect(imported_digital_object.linked_agents).to eq([])
    end

    before(:each) { @original_count = AgentPerson.count }

    it "keeps a Contact that has only a name and creates no telephone" do
      report = run_agent_import(contact_group)

      expect(report.rows[0].errors).to eq([])
      contact = linked_agent_records(imported_digital_object).first.agent_contacts.first
      expect(contact["name"]).to eq("Contact Name #{@now}")
      expect(contact["telephones"]).to eq([])
    end

    it "uses the importing user's publish preference when publish is blank" do
      expect(Preference.defaults["publish"]).to be_falsey
      Preference.create_from_json(
        JSONModel(:preference).from_hash("defaults" => { "publish" => true }),
        :user_id => @current_user.id
      )
      expect(Preference.defaults["publish"]).to eq(true)

      report = run_agent_import(contact_group)

      expect(report.rows[0].errors).to eq([])
      expect(linked_agent_records(imported_digital_object).first.publish).to eq(true)
    end

    it "reports an unrecognized publish value by its uploaded column" do
      report = run_agent_import(person_group("agent_1_publish" => "maybe"))

      expect_no_agent_created(report, "agent_1_publish", "maybe", "YES", "FALSE")
    end

    it "reports a conflict between a Header String and publish" do
      report = run_agent_import(
        "agent_1_agent_type" => "agent_person",
        "agent_1_header" => "Header Person #{@now}",
        "agent_1_publish" => "yes"
      )

      expect_no_agent_created(report, "agent_1_header")
    end

    it "requires a Contact name when any contact, telephone or fax field is populated" do
      report = run_agent_import(person_group("agent_1_agent_contact_1_fax_1_number" => "555-0199"))

      expect_no_agent_created(report, "agent_1_agent_contact_1_name")
    end

    it "reports an unrecognized salutation by its uploaded column" do
      report = run_agent_import(contact_group("agent_1_agent_contact_1_salutation" => "your-grace"))

      expect_no_agent_created(report, "agent_1_agent_contact_1_salutation", "your-grace")
    end

    it "rejects a telephone extension supplied without a telephone number" do
      report = run_agent_import(contact_group("agent_1_agent_contact_1_telephone_1_ext" => "42"))

      expect_no_agent_created(report, "agent_1_agent_contact_1_telephone_1_number")
    end

    it "keeps a fax on its own when no telephone is supplied" do
      report = run_agent_import(contact_group("agent_1_agent_contact_1_fax_1_number" => "555-0199"))

      expect(report.rows[0].errors).to eq([])
      contact = linked_agent_records(imported_digital_object).first.agent_contacts.first
      expect(contact["telephones"].map { |phone| phone.slice("number_type", "number") }).to eq(
        [{ "number_type" => "fax", "number" => "555-0199" }]
      )
    end

    it "builds a note from content alone" do
      report = run_agent_import(person_group("agent_1_note_1_content" => "Only content #{@now}"))

      expect(report.rows[0].errors).to eq([])
      subnotes = linked_agent_records(imported_digital_object).first.notes.first["subnotes"]
      expect(subnotes.map { |subnote| subnote["jsonmodel_type"] }).to eq(%w[note_text])
    end

    it "builds a note from a citation alone" do
      report = run_agent_import(person_group("agent_1_note_1_citation" => "Only citation #{@now}"))

      expect(report.rows[0].errors).to eq([])
      subnotes = linked_agent_records(imported_digital_object).first.notes.first["subnotes"]
      expect(subnotes.map { |subnote| subnote["jsonmodel_type"] }).to eq(%w[note_citation])
    end

    it "creates no Agent in validate-only mode" do
      report = run_agent_import(contact_group("agent_1_publish" => "yes"), true)

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])
      expect(AgentPerson.count).to eq(@original_count)
    end
  end

  context "mixing link or Header String fields with creation fields" do
    it "reports a conflict between an existing-record reference and creation fields and imports the Digital Object without an Agent" do
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_record_id" => "12345"))

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.join(" ")).to include("agent_1_record_id")
      expect(AgentPerson.count).to eq(original_count)
      expect(imported_digital_object.linked_agents).to eq([])
    end

    it "reports a conflict between a Header String and creation fields and imports the Digital Object without an Agent" do
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_header" => "Header Person #{@now}"))

      expect(report.rows[0].errors.join(" ")).to include("agent_1_header")
      expect(AgentPerson.count).to eq(original_count)
      expect(imported_digital_object.linked_agents).to eq([])
    end

    it "reports a mode conflict and an invalid role together" do
      bad_role = "not-a-role-#{@now}"
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_header" => "Header Person #{@now}", "agent_1_role" => bad_role))

      errors = report.rows[0].errors.join(" ")
      expect(errors).to include("agent_1_header")
      expect(errors).to include(bad_role)
      expect(AgentPerson.count).to eq(original_count)
      expect(imported_digital_object.linked_agents).to eq([])
    end

    it "links nothing when a canonical URI of an existing Agent is combined with creation fields" do
      existing = create(:json_agent_person)
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_record_id" => existing.uri))

      expect(report.rows[0].errors.join(" ")).to include("agent_1_record_id")
      expect(AgentPerson.count).to eq(original_count)
      expect(imported_digital_object.linked_agents).to eq([])
    end

    it "links nothing when a numeric ID of an existing Agent is combined with creation fields" do
      existing = create(:json_agent_person)
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_record_id" => existing.id.to_s))

      expect(report.rows[0].errors.join(" ")).to include("agent_1_record_id")
      expect(AgentPerson.count).to eq(original_count)
      expect(imported_digital_object.linked_agents).to eq([])
    end

    it "links nothing when the Header String of an existing Agent is combined with creation fields" do
      existing = create(:json_agent_person)
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_header" => existing.title))

      expect(report.rows[0].errors.join(" ")).to include("agent_1_header")
      expect(AgentPerson.count).to eq(original_count)
      expect(imported_digital_object.linked_agents).to eq([])
    end
  end

  context "linking an existing Agent by record ID or URI" do
    def linked_refs
      imported_digital_object.linked_agents.map { |link| link["ref"] }
    end

    it "links an existing Agent by canonical URI and derives the type" do
      person = create(:json_agent_person)
      family = create(:json_agent_family)
      original_people = AgentPerson.count

      report = run_agent_import(
        "agent_1_record_id" => person.uri,
        "agent_2_record_id" => family.uri
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])
      expect(linked_refs).to match_array([person.uri, family.uri])
      expect(AgentPerson.count).to eq(original_people)
    end

    it "links an existing Agent by numeric ID and type without creating another" do
      person = create(:json_agent_person)
      original_people = AgentPerson.count

      report = run_agent_import(
        "agent_1_agent_type" => "agent_person",
        "agent_1_record_id" => person.uri[/\d+\z/]
      )

      expect(report.rows[0].errors).to eq([])
      expect(linked_refs).to eq([person.uri])
      expect(AgentPerson.count).to eq(original_people)
    end

    it "links the numeric match and ignores a Header String" do
      person = create(:json_agent_person)
      original_people = AgentPerson.count

      report = run_agent_import(
        "agent_1_agent_type" => "agent_person",
        "agent_1_record_id" => person.uri[/\d+\z/],
        "agent_1_header" => "Ignored header #{@now}"
      )

      expect(report.rows[0].errors).to eq([])
      expect(linked_refs).to eq([person.uri])
      expect(AgentPerson.count).to eq(original_people)
    end

    it "trims whitespace around a numeric ID and a URI" do
      person = create(:json_agent_person)
      family = create(:json_agent_family)

      report = run_agent_import(
        "agent_1_agent_type" => "agent_person",
        "agent_1_record_id" => " #{person.uri[/\d+\z/]} ",
        "agent_2_record_id" => " #{family.uri} "
      )

      expect(report.rows[0].errors).to eq([])
      expect(linked_refs).to match_array([person.uri, family.uri])
    end

    it "falls back to the Header String when a numeric ID matches nothing" do
      report = run_agent_import(
        "agent_1_agent_type" => "agent_person",
        "agent_1_record_id" => "987654321",
        "agent_1_header" => "Fallback Person #{@now}"
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])
      agents = linked_agent_records(imported_digital_object)
      expect(agents.map(&:title)).to eq(["Fallback Person #{@now}"])
    end

    it "reports a URI combined with an Agent Type and links nothing" do
      person = create(:json_agent_person)

      report = run_agent_import(
        "agent_1_agent_type" => "agent_person",
        "agent_1_record_id" => person.uri
      )

      expect(report.rows[0].errors.join(" ")).to include("agent_1_agent_type must be blank")
      expect(linked_refs).to eq([])
    end

    it "reports a URI combined with a Header String as a conflict and links nothing" do
      person = create(:json_agent_person)
      original_people = AgentPerson.count

      report = run_agent_import(
        "agent_1_record_id" => person.uri,
        "agent_1_header" => "Header Person #{@now}"
      )

      errors = report.rows[0].errors
      expect(errors.length).to eq(1)
      expect(errors.first).to include("agent_1_record_id")
      expect(errors.first).to include("agent_1_header")
      expect(errors.first).not_to include("creation fields")
      expect(linked_refs).to eq([])
      expect(AgentPerson.count).to eq(original_people)
    end

    it "reports a software Agent URI as unsupported and links nothing" do
      report = run_agent_import("agent_1_record_id" => "/agents/software/1")

      expect(report.rows[0].errors.join(" ")).to include("agent_1_record_id is a URI for an unsupported agent type")
      expect(linked_refs).to eq([])
    end

    it "reports a URI that matches no Agent and creates nothing" do
      original_people = AgentPerson.count

      report = run_agent_import("agent_1_record_id" => "/agents/people/987654321")

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.join(" ")).to include("agent_1_record_id does not match an existing agent")
      expect(linked_refs).to eq([])
      expect(AgentPerson.count).to eq(original_people)
    end

    it "reports the conflict, not a missing target, when a URI and Header String are both given" do
      original_people = AgentPerson.count

      report = run_agent_import(
        "agent_1_record_id" => "/agents/people/987654321",
        "agent_1_header" => "Header Person #{@now}"
      )

      errors = report.rows[0].errors
      expect(errors.length).to eq(1)
      expect(errors.first).to include("cannot be used together")
      expect(AgentPerson.count).to eq(original_people)
    end

    ["/agents/people/abc", "/agents/people/007", "/subjects/5"].each do |bad|
      it "reports #{bad.inspect} as an invalid record ID and links nothing" do
        report = run_agent_import("agent_1_record_id" => bad)

        expect(report.rows[0].errors.join(" ")).to include("agent_1_record_id must be a positive numeric ID or a canonical agent URI")
        expect(linked_refs).to eq([])
      end
    end

    ["0", "007", "abc", "-3", "5.0"].each do |bad|
      it "reports the numeric ID #{bad.inspect} as invalid, even with a Header String, and creates no placeholder" do
        original_people = AgentPerson.count

        report = run_agent_import(
          "agent_1_agent_type" => "agent_person",
          "agent_1_record_id" => bad,
          "agent_1_header" => "Header Person #{@now}"
        )

        expect(report.rows[0].errors.join(" ")).to include("agent_1_record_id must be a positive numeric ID or a canonical agent URI")
        expect(linked_refs).to eq([])
        expect(AgentPerson.count).to eq(original_people)
      end
    end

    it "reports a numeric ID without an Agent Type and links nothing" do
      person = create(:json_agent_person)

      report = run_agent_import("agent_1_record_id" => person.uri[/\d+\z/])

      expect(report.rows[0].errors.join(" ")).to match(/agent type/i)
      expect(linked_refs).to eq([])
    end

    it "validates the role before looking up a URI" do
      report = run_agent_import(
        "agent_1_record_id" => "/agents/people/987654321",
        "agent_1_role" => "not-a-role"
      )

      errors = report.rows[0].errors.join(" ")
      expect(errors).to include("not-a-role")
      expect(errors).not_to include("987654321")
      expect(linked_refs).to eq([])
    end

    it "preserves an explicit role and relator on a URI link" do
      person = create(:json_agent_person)

      report = run_agent_import(
        "agent_1_record_id" => person.uri,
        "agent_1_role" => "source",
        "agent_1_relator" => "aut"
      )

      expect(report.rows[0].errors).to eq([])
      link = imported_digital_object.linked_agents.first
      expect(link["ref"]).to eq(person.uri)
      expect(link["role"]).to eq("source")
      expect(link["relator"]).to eq("aut")
    end

    it "defaults the role to creator on a URI link" do
      person = create(:json_agent_person)

      run_agent_import("agent_1_record_id" => person.uri)

      expect(imported_digital_object.linked_agents.first["role"]).to eq("creator")
    end

    it "links nothing and imports nothing in validate-only mode when the URI matches" do
      person = create(:json_agent_person)

      report = run_agent_import({ "agent_1_record_id" => person.uri }, true)

      expect(report.rows[0].errors).to eq([])
      expect(DigitalObject.where(:title => "Digital Object Title #{@now}").count).to eq(0)
    end

    it "reports a missing URI target in validate-only mode" do
      report = run_agent_import({ "agent_1_record_id" => "/agents/people/987654321" }, true)

      expect(report.rows[0].errors.join(" ")).to include("agent_1_record_id does not match an existing agent")
    end
  end

  context "relationship validation" do
    it "creates and links no Agent when the relator is invalid" do
      bad_relator = "not-a-relator-#{@now}"
      original_count = AgentPerson.count

      report = run_agent_import(
        "agent_1_agent_type" => "agent_person",
        "agent_1_header" => "Orphan Relator Person #{@now}",
        "agent_1_relator" => bad_relator
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.join(" ")).to include(bad_relator)
      expect(AgentPerson.count).to eq(original_count)
      expect(imported_digital_object.linked_agents).to eq([])
    end

    it "creates and links no Agent when the role is invalid" do
      bad_role = "not-a-role-#{@now}"
      original_count = AgentPerson.count

      report = run_agent_import(
        "agent_1_agent_type" => "agent_person",
        "agent_1_header" => "Orphan Person #{@now}",
        "agent_1_role" => bad_role
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.join(" ")).to include(bad_role)
      expect(AgentPerson.count).to eq(original_count)
      expect(imported_digital_object.linked_agents).to eq([])
    end

    it "reports an invalid role together with an invalid record ID" do
      bad_role = "not-a-role-#{@now}"

      report = run_agent_import(
        "agent_1_agent_type" => "agent_person",
        "agent_1_record_id" => "abc",
        "agent_1_role" => bad_role
      )

      errors = report.rows[0].errors.join(" ")
      expect(errors).to include(bad_role)
      expect(errors).to include("abc")
      expect(imported_digital_object.linked_agents).to eq([])
    end

    it "reports an invalid role together with a missing primary name" do
      bad_role = "not-a-role-#{@now}"
      original_count = AgentPerson.count

      report = run_agent_import(
        person_group("agent_1_agent_name_1_primary_name" => nil, "agent_1_role" => bad_role)
      )

      errors = report.rows[0].errors.join(" ")
      expect(errors).to include(bad_role)
      expect(errors).to include("agent_1_agent_name_1_primary_name")
      expect(AgentPerson.count).to eq(original_count)
      expect(imported_digital_object.linked_agents).to eq([])
    end
  end

  context "isolating invalid Agent groups" do
    def group_three_person(overrides = {})
      {
        "agent_3_agent_type" => "agent_person",
        "agent_3_agent_name_1_primary_name" => "Third Person #{@now}",
        "agent_3_agent_name_1_name_order" => "direct",
      }.merge(overrides)
    end

    it "creates a valid Agent and reports an invalid sibling Agent group" do
      original_count = AgentPerson.count

      report = run_agent_import(
        person_group.merge(group_three_person("agent_3_agent_name_1_primary_name" => nil))
      )

      expect(report.rows[0].errors.join(" ")).to include("agent_3_agent_name_1_primary_name")
      expect(AgentPerson.count).to eq(original_count + 1)
      expect(imported_digital_object.linked_agents.length).to eq(1)
    end

    it "links an existing Agent and reports a conflicting sibling Agent group" do
      existing = create(:json_agent_person)
      original_count = AgentPerson.count

      report = run_agent_import(
        "agent_1_record_id" => existing.uri,
        "agent_3_agent_type" => "agent_person",
        "agent_3_header" => "Header Person #{@now}",
        "agent_3_agent_name_1_primary_name" => "Third Person #{@now}",
        "agent_3_agent_name_1_name_order" => "direct"
      )

      expect(report.rows[0].errors.join(" ")).to include("agent_3_header")
      expect(AgentPerson.count).to eq(original_count)
      expect(imported_digital_object.linked_agents.map { |link| link["ref"] }).to eq([existing.uri])
    end

    it "reports the same errors and persists nothing in validate-only mode" do
      original_count = AgentPerson.count

      report = run_agent_import(
        person_group.merge(group_three_person("agent_3_agent_name_1_primary_name" => nil)),
        true
      )

      expect(report.rows[0].errors.join(" ")).to include("agent_3_agent_name_1_primary_name")
      expect(AgentPerson.count).to eq(original_count)
      expect(DigitalObject.where(:title => "Digital Object Title #{@now}").count).to eq(0)
    end
  end

  context "reporting Agent identity collisions" do
    def colliding_group_three(overrides = {})
      {
        "agent_3_agent_type" => "agent_person",
        "agent_3_agent_name_1_primary_name" => "Created Person #{@now}",
        "agent_3_agent_name_1_name_order" => "direct",
      }.merge(overrides)
    end

    it "reports a fingerprint collision differing only in publish and keeps the valid sibling and the Digital Object" do
      original_count = AgentPerson.count

      report = run_agent_import(
        person_group("agent_1_publish" => "true").merge(colliding_group_three("agent_3_publish" => "false"))
      )

      expect(report.rows[0].errors).to eq([I18n.t("bulk_import.error.agent_fingerprint_collision", :num => 3)])
      expect(DigitalObject.where(:title => "Digital Object Title #{@now}").count).to eq(1)
      expect(AgentPerson.count).to eq(original_count + 1)
      expect(imported_digital_object.linked_agents.length).to eq(1)
    end

    it "reports a fingerprint collision differing only in an explicit Sort Name" do
      original_count = AgentPerson.count

      report = run_agent_import(
        person_group.merge(colliding_group_three("agent_3_agent_name_1_sort_name" => "Custom Sort #{@now}"))
      )

      expect(report.rows[0].errors).to eq([I18n.t("bulk_import.error.agent_fingerprint_collision", :num => 3)])
      expect(AgentPerson.count).to eq(original_count + 1)
      expect(imported_digital_object.linked_agents.length).to eq(1)
    end

    it "reports a fingerprint collision differing only in nested telephone data" do
      original_count = AgentPerson.count

      report = run_agent_import(
        person_group(
          "agent_1_agent_contact_1_name" => "Contact #{@now}",
          "agent_1_agent_contact_1_telephone_1_number" => "555-0100"
        ).merge(
          colliding_group_three(
            "agent_3_agent_contact_1_name" => "Contact #{@now}",
            "agent_3_agent_contact_1_telephone_1_number" => "555-0199"
          )
        )
      )

      expect(report.rows[0].errors).to eq([I18n.t("bulk_import.error.agent_fingerprint_collision", :num => 3)])
      expect(AgentPerson.count).to eq(original_count + 1)
      expect(imported_digital_object.linked_agents.length).to eq(1)
    end

    it "reports an authority ID collision between Agents with different names" do
      original_count = AgentPerson.count

      report = run_agent_import(
        person_group("agent_1_agent_name_1_authority_id" => "collide-#{@now}", "agent_1_agent_name_1_source" => "naf").merge(
          colliding_group_three(
            "agent_3_agent_name_1_primary_name" => "Other Person #{@now}",
            "agent_3_agent_name_1_authority_id" => "collide-#{@now}",
            "agent_3_agent_name_1_source" => "naf"
          )
        )
      )

      expect(report.rows[0].errors).to eq([I18n.t("bulk_import.error.agent_authority_id_collision", :num => 3)])
      expect(DigitalObject.where(:title => "Digital Object Title #{@now}").count).to eq(1)
      expect(AgentPerson.count).to eq(original_count + 1)
      expect(imported_digital_object.linked_agents.length).to eq(1)
    end

    it "reports an authority ID collision with an existing Agent in validate-only mode" do
      run_agent_import(
        person_group("agent_1_agent_name_1_authority_id" => "existing-#{@now}", "agent_1_agent_name_1_source" => "naf")
      )
      original_count = AgentPerson.count

      report = run_agent_import(
        person_group(
          "agent_1_agent_name_1_primary_name" => "Other Person #{@now}",
          "agent_1_agent_name_1_authority_id" => "existing-#{@now}",
          "agent_1_agent_name_1_source" => "naf"
        ),
        true
      )

      expect(report.rows[0].errors).to eq([I18n.t("bulk_import.error.agent_authority_id_collision", :num => 1)])
      expect(AgentPerson.count).to eq(original_count)
    end
  end

  context "structural Agent indices in uploaded headers" do
    def run_with_extra_headers(extra_headers)
      csv_data = CSV.read(File.join(TEMPLATES_DIR, "bulk_import_DO_template.csv"))
      columns = csv_data[0].dup + extra_headers
      column_explanations = csv_data[1].dup + extra_headers.map { "Agent" }

      row = {}
      columns.each { |column| row[column] = nil }
      row["res_uri"] = @resource.uri
      row["ao_uri"] = @archival_object.uri
      row["digital_object_title"] = "Digital Object Title #{@now}"

      import_digital_object_csv(columns, column_explanations, row)
    end

    def person_group_at(index)
      {
        "agent_#{index}_agent_type" => "agent_person",
        "agent_#{index}_agent_name_1_primary_name" => "Person #{index} #{@now}",
        "agent_#{index}_agent_name_1_name_order" => "direct",
      }
    end

    it "creates and links rich Agents from noncontiguous groups and ignores a blank group between them" do
      report = run_agent_import(
        person_group_at(2).merge(person_group_at(7)).merge("agent_4_agent_type" => nil, "agent_4_publish" => nil)
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])
      expect(linked_agent_records(imported_digital_object).map(&:title)).to match_array(
        ["Person 2 #{@now}", "Person 7 #{@now}"]
      )
    end

    it "treats a populated higher-index publish-only group as a partial rich group and reports its missing data" do
      original_count = AgentPerson.count

      report = run_agent_import("agent_6_publish" => "true")

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.join(" ")).to include("agent_6_")
      expect(AgentPerson.count).to eq(original_count)
    end

    it "stops the upload when a column uses the zero index" do
      report = run_with_extra_headers(%w[agent_0_agent_type])

      expect(report.terminal_error).to include("agent_0_agent_type")
      expect(DigitalObject.where(:title => "Digital Object Title #{@now}").count).to eq(0)
    end

    it "stops the upload when a higher-index column has a leaf the template does not define" do
      report = run_with_extra_headers(%w[agent_3_not_a_field])

      expect(report.terminal_error).to include("agent_3_not_a_field")
      expect(DigitalObject.where(:title => "Digital Object Title #{@now}").count).to eq(0)
    end

    it "stops the upload when a column has a malformed Agent index" do
      report = run_with_extra_headers(%w[agent_x_agent_type agent_01_agent_type])

      expect(report.terminal_error).to include("agent_x_agent_type", "agent_01_agent_type")
      expect(DigitalObject.where(:title => "Digital Object Title #{@now}").count).to eq(0)
    end
  end
end
