require "spec_helper"
require_relative "../app/lib/bulk_import/import_digital_objects.rb"
require_relative "lib_bulk_import_import_digital_objects_shared_context"

describe "Import Digital Objects Agents" do
  include_context "digital object importer harness"

  TEMPLATES_DIR = File.join(File.dirname(__FILE__), "../", "../", "frontend", "public", "bulk_import_templates") unless defined?(TEMPLATES_DIR)

  def run_agent_import(row_overrides, validate_only = false)
    rows_overrides = row_overrides.is_a?(Array) ? row_overrides : [row_overrides]
    csv_data = CSV.read(File.join(TEMPLATES_DIR, "bulk_import_DO_template.csv"))
    columns = csv_data[0].dup
    column_explanations = csv_data[1].dup
    rows_overrides.flat_map(&:keys).map { |key| key[/\Aagent_(\d+)_/, 1] }.compact.uniq.each do |index|
      next if columns.any? { |column| column.to_s.start_with?("agent_#{index}_") }

      extra = family_headers_at(csv_data[0], "agent", index)
      columns += extra
      column_explanations += extra.map { "Agent(#{index})" }
    end

    rows = rows_overrides.map do |overrides|
      row = {}
      columns.each { |column| row[column] = nil }
      row["res_uri"] = @resource.uri
      row["ao_uri"] = @archival_object.uri
      row["digital_object_title"] = "Digital Object Title #{@now}"
      overrides.each { |key, value| row[key] = value }
      row
    end

    import_digital_object_csv(columns, column_explanations, rows, validate_only: validate_only)
  end

  def digital_object_count(title = "Digital Object Title #{@now}")
    DigitalObject.where(:title => title).count
  end

  def digital_object_titled(title)
    ::DigitalObject.to_jsonmodel(DigitalObject.where(:title => title).first.id)
  end

  def person_group(overrides = {})
    {
      "agent_1_agent_type" => "person",
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
        "agent_10_agent_type" => "person",
        "agent_10_header" => "Person ten #{@now}",
        "agent_3_agent_type" => "person",
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
        "agent_1_agent_type" => "person",
        "agent_1_header" => "Minimal Person #{@now}"
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])
      expect(linked_agent_records(imported_digital_object).map(&:publish)).to eq([true])
    end

    it "creates an unpublished placeholder Agent for an unresolved numeric ID" do
      report = run_agent_import(
        "agent_1_agent_type" => "person",
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
        "agent_1_agent_type" => "person",
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
        "agent_1_agent_type" => "person",
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
        "agent_1_agent_type" => "person",
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
        "agent_1_agent_type" => "family",
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
        "agent_1_agent_type" => "family",
        "agent_1_agent_name_1_primary_name" => "Created Family #{@now}",
        "agent_1_agent_name_1_title" => "Dr"
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.join(" ")).to include("agent_1_agent_name_1_title", "'family'")
      expect(AgentFamily.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
    end
  end

  context "corporate entity Agent creation" do
    it "creates a corporate entity with its subordinate names and explicit Sort Name" do
      original_count = AgentCorporateEntity.count

      report = run_agent_import(
        "agent_1_agent_type" => "corporate_entity",
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
        "agent_1_agent_type" => "person",
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

    it "reports a missing primary name by its uploaded column and imports no Digital Object" do
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_agent_name_1_primary_name" => nil))

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.join(" ")).to include("agent_1_agent_name_1_primary_name")
      expect(AgentPerson.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
    end

    it "reports a missing Agent type by its uploaded column and imports no Digital Object" do
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_agent_type" => nil))

      expect(report.rows[0].errors.join(" ")).to include("agent_1_agent_type")
      expect(AgentPerson.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
    end

    it "reports a missing Name Order by its uploaded column and imports no Digital Object" do
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_agent_name_1_name_order" => nil))

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.join(" ")).to include("agent_1_agent_name_1_name_order")
      expect(AgentPerson.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
    end

    it "reports an unrecognized Name Order by its uploaded column and imports no Digital Object" do
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_agent_name_1_name_order" => "sideways"))

      expect(report.rows[0].errors.join(" ")).to include("agent_1_agent_name_1_name_order", "sideways")
      expect(AgentPerson.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
    end

    it "reports a prefixed Agent type as unsupported and imports no Digital Object" do
      original_count = AgentFamily.count

      report = run_agent_import(person_group("agent_1_agent_type" => "agent_family"))

      expect(report.rows[0].errors.join(" ")).to include("Agent 1 has an unsupported agent type. Accepted values: family, corporate_entity, person")
      expect(AgentFamily.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
    end

    it "reports an invalid role and imports no Digital Object" do
      original_count = AgentPerson.count
      bad_role = "not-a-role-#{@now}"

      report = run_agent_import(person_group("agent_1_role" => bad_role))

      expect(report.rows[0].errors.join(" ")).to include(bad_role)
      expect(AgentPerson.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
    end

    it "creates no Agent and no Digital Object in validate-only mode" do
      original_count = AgentPerson.count

      report = run_agent_import(person_group, true)

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])
      expect(AgentPerson.count).to eq(original_count)
      expect(DigitalObject.where(:title => "Digital Object Title #{@now}").count).to eq(0)
    end

    it "reports an Agent that fails schema validation and imports no Digital Object" do
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_agent_name_1_primary_name" => "x" * 256))

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.join(" ")).to include("primary_name")
      expect(AgentPerson.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
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
      expect(digital_object_count).to eq(0)
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
        "agent_1_agent_type" => "person",
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
    it "reports a conflict between an existing-record reference and creation fields and imports no Digital Object" do
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_record_id" => "12345"))

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.join(" ")).to include("agent_1_record_id")
      expect(AgentPerson.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
    end

    it "reports a conflict between a Header String and creation fields and imports no Digital Object" do
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_header" => "Header Person #{@now}"))

      expect(report.rows[0].errors.join(" ")).to include("agent_1_header")
      expect(AgentPerson.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
    end

    it "reports a mode conflict and an invalid role together" do
      bad_role = "not-a-role-#{@now}"
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_header" => "Header Person #{@now}", "agent_1_role" => bad_role))

      errors = report.rows[0].errors.join(" ")
      expect(errors).to include("agent_1_header")
      expect(errors).to include(bad_role)
      expect(AgentPerson.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
    end

    it "links nothing when a canonical URI of an existing Agent is combined with creation fields" do
      existing = create(:json_agent_person)
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_record_id" => existing.uri))

      expect(report.rows[0].errors.join(" ")).to include("agent_1_record_id")
      expect(AgentPerson.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
    end

    it "links nothing when a numeric ID of an existing Agent is combined with creation fields" do
      existing = create(:json_agent_person)
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_record_id" => existing.id.to_s))

      expect(report.rows[0].errors.join(" ")).to include("agent_1_record_id")
      expect(AgentPerson.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
    end

    it "links nothing when the Header String of an existing Agent is combined with creation fields" do
      existing = create(:json_agent_person)
      original_count = AgentPerson.count

      report = run_agent_import(person_group("agent_1_header" => existing.title))

      expect(report.rows[0].errors.join(" ")).to include("agent_1_header")
      expect(AgentPerson.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
    end

    it "names the filled Publish column next to the record ID column" do
      existing = create(:json_agent_person)

      report = run_agent_import("agent_1_record_id" => existing.uri, "agent_1_publish" => "yes")

      expect(report.rows[0].errors).to eq([
        "Agent 1, field agent_1_record_id, cannot be combined with agent creation fields (agent_1_publish). No agent was created or linked",
        I18n.t("bulk_import.error.dig_row_not_saved"),
      ])
    end

    it "names every filled creation column next to the Header String column, in header order" do
      creation_columns = person_group.keys - ["agent_1_agent_type"]

      report = run_agent_import(person_group("agent_1_header" => "Header Person #{@now}"))

      expect(report.rows[0].errors.first).to eq(
        I18n.t("bulk_import.error.agent_mode_conflict", :num => 1, :field => "agent_1_header", :creation_fields => creation_columns.join(", "))
      )
      expect(report.rows[0].errors.first).to include("(#{creation_columns.join(", ")})")
    end

    it "names the filled Publish column in the error for each linking column" do
      existing = create(:json_agent_person)

      report = run_agent_import(
        "agent_1_record_id" => existing.uri,
        "agent_1_header" => "Header Person #{@now}",
        "agent_1_publish" => "yes"
      )

      conflicts = report.rows[0].errors - [I18n.t("bulk_import.error.dig_row_not_saved")]
      expect(conflicts.length).to eq(2)
      expect(conflicts).to all(include("(agent_1_publish)"))
      expect(conflicts[0]).to include("agent_1_record_id")
      expect(conflicts[1]).to include("agent_1_header")
    end

    it "names the filled Publish column in validate-only mode" do
      existing = create(:json_agent_person)

      report = run_agent_import({ "agent_1_record_id" => existing.uri, "agent_1_publish" => "yes" }, true)

      expect(report.rows[0].errors.first).to eq(
        "Agent 1, field agent_1_record_id, cannot be combined with agent creation fields (agent_1_publish). No agent was created or linked"
      )
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
        "agent_1_agent_type" => "person",
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
        "agent_1_agent_type" => "person",
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
        "agent_1_agent_type" => "person",
        "agent_1_record_id" => " #{person.uri[/\d+\z/]} ",
        "agent_2_record_id" => " #{family.uri} "
      )

      expect(report.rows[0].errors).to eq([])
      expect(linked_refs).to match_array([person.uri, family.uri])
    end

    it "falls back to the Header String when a numeric ID matches nothing" do
      report = run_agent_import(
        "agent_1_agent_type" => "person",
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
        "agent_1_agent_type" => "person",
        "agent_1_record_id" => person.uri
      )

      expect(report.rows[0].errors.join(" ")).to include("agent_1_agent_type, must be blank")
      expect(digital_object_count).to eq(0)
    end

    it "reports a URI combined with a Header String as a conflict and links nothing" do
      person = create(:json_agent_person)
      original_people = AgentPerson.count

      report = run_agent_import(
        "agent_1_record_id" => person.uri,
        "agent_1_header" => "Header Person #{@now}"
      )

      errors = report.rows[0].errors
      expect(errors.length).to eq(2)
      expect(errors.last).to eq(I18n.t("bulk_import.error.dig_row_not_saved"))
      expect(errors.first).to include("agent_1_record_id")
      expect(errors.first).to include("agent_1_header")
      expect(errors.first).not_to include("creation fields")
      expect(digital_object_count).to eq(0)
      expect(AgentPerson.count).to eq(original_people)
    end

    it "reports a software Agent URI as unsupported and links nothing" do
      report = run_agent_import("agent_1_record_id" => "/agents/software/1")

      errors = report.rows[0].errors.join(" ")
      expect(errors).to include("Agent 1, field agent_1_record_id, is a URI for an agent type that cannot be used here. Accepted values: family, corporate_entity, person")
      expect(errors).not_to include("/agents/software/1")
      expect(digital_object_count).to eq(0)
    end

    it "reports a numeric ID with a software Agent type as unsupported and links nothing" do
      report = run_agent_import("agent_1_record_id" => "1", "agent_1_agent_type" => "software")

      expect(report.rows[0].errors.join(" ")).to include("Agent 1 has an unsupported agent type. Accepted values: family, corporate_entity, person")
      expect(digital_object_count).to eq(0)
    end

    it "links an existing Agent by numeric ID with a mixed-case, padded Agent type" do
      person = create(:json_agent_person)
      id = JSONModel.parse_reference(person.uri)[:id]

      report = run_agent_import("agent_1_record_id" => id.to_s, "agent_1_agent_type" => " Person ")

      expect(report.rows[0].errors).to eq([])
      expect(linked_refs).to eq([person.uri])
    end

    it "reports a URI that matches no Agent and creates nothing" do
      original_people = AgentPerson.count

      report = run_agent_import("agent_1_record_id" => "/agents/people/987654321")

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.join(" ")).to include("agent_1_record_id, does not match an existing agent")
      expect(digital_object_count).to eq(0)
      expect(AgentPerson.count).to eq(original_people)
    end

    it "reports the conflict, not a missing target, when a URI and Header String are both given" do
      original_people = AgentPerson.count

      report = run_agent_import(
        "agent_1_record_id" => "/agents/people/987654321",
        "agent_1_header" => "Header Person #{@now}"
      )

      errors = report.rows[0].errors
      expect(errors.length).to eq(2)
      expect(errors.last).to eq(I18n.t("bulk_import.error.dig_row_not_saved"))
      expect(errors.first).to include("cannot be used together")
      expect(AgentPerson.count).to eq(original_people)
    end

    ["/agents/people/abc", "/agents/people/007", "/subjects/5"].each do |bad|
      it "reports #{bad.inspect} as an invalid record ID and links nothing" do
        report = run_agent_import("agent_1_record_id" => bad)

        expect(report.rows[0].errors.join(" ")).to include("agent_1_record_id, must be a positive numeric ID or a canonical agent URI")
        expect(digital_object_count).to eq(0)
      end
    end

    ["0", "007", "abc", "-3", "5.0"].each do |bad|
      it "reports the numeric ID #{bad.inspect} as invalid, even with a Header String, and creates no placeholder" do
        original_people = AgentPerson.count

        report = run_agent_import(
          "agent_1_agent_type" => "person",
          "agent_1_record_id" => bad,
          "agent_1_header" => "Header Person #{@now}"
        )

        expect(report.rows[0].errors.join(" ")).to include("agent_1_record_id, must be a positive numeric ID or a canonical agent URI")
        expect(digital_object_count).to eq(0)
        expect(AgentPerson.count).to eq(original_people)
      end
    end

    it "reports a numeric ID without an Agent Type and links nothing" do
      person = create(:json_agent_person)

      report = run_agent_import("agent_1_record_id" => person.uri[/\d+\z/])

      expect(report.rows[0].errors.join(" ")).to match(/agent type/i)
      expect(digital_object_count).to eq(0)
    end

    it "validates the role before looking up a URI" do
      report = run_agent_import(
        "agent_1_record_id" => "/agents/people/987654321",
        "agent_1_role" => "not-a-role"
      )

      errors = report.rows[0].errors.join(" ")
      expect(errors).to include("not-a-role")
      expect(errors).not_to include("987654321")
      expect(digital_object_count).to eq(0)
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

      expect(report.rows[0].errors.join(" ")).to include("agent_1_record_id, does not match an existing agent")
    end
  end

  context "relationship validation" do
    it "creates and links no Agent when the relator is invalid" do
      bad_relator = "not-a-relator-#{@now}"
      original_count = AgentPerson.count

      report = run_agent_import(
        "agent_1_agent_type" => "person",
        "agent_1_header" => "Orphan Relator Person #{@now}",
        "agent_1_relator" => bad_relator
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.join(" ")).to include(bad_relator)
      expect(AgentPerson.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
    end

    it "creates and links no Agent when the role is invalid" do
      bad_role = "not-a-role-#{@now}"
      original_count = AgentPerson.count

      report = run_agent_import(
        "agent_1_agent_type" => "person",
        "agent_1_header" => "Orphan Person #{@now}",
        "agent_1_role" => bad_role
      )

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors.join(" ")).to include(bad_role)
      expect(AgentPerson.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
    end

    it "reports an invalid role together with an invalid record ID" do
      bad_role = "not-a-role-#{@now}"

      report = run_agent_import(
        "agent_1_agent_type" => "person",
        "agent_1_record_id" => "abc",
        "agent_1_role" => bad_role
      )

      errors = report.rows[0].errors.join(" ")
      expect(errors).to include(bad_role)
      expect(errors).to include("abc")
      expect(digital_object_count).to eq(0)
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
      expect(digital_object_count).to eq(0)
    end
  end

  context "failing the row on an invalid Agent or Subject group" do
    def group_three_person(overrides = {})
      {
        "agent_3_agent_type" => "person",
        "agent_3_agent_name_1_primary_name" => "Third Person #{@now}",
        "agent_3_agent_name_1_name_order" => "direct",
      }.merge(overrides)
    end

    it "creates no valid sibling Agent and no Digital Object when another Agent group is invalid" do
      original_count = AgentPerson.count

      report = run_agent_import(
        person_group.merge(group_three_person("agent_3_agent_name_1_primary_name" => nil))
      )

      expect(report.rows[0].errors.join(" ")).to include("agent_3_agent_name_1_primary_name")
      expect(AgentPerson.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
    end

    it "links no existing Agent and imports no Digital Object when a sibling Agent group conflicts" do
      existing = create(:json_agent_person)
      original_count = AgentPerson.count

      report = run_agent_import(
        "agent_1_record_id" => existing.uri,
        "agent_3_agent_type" => "person",
        "agent_3_header" => "Header Person #{@now}",
        "agent_3_agent_name_1_primary_name" => "Third Person #{@now}",
        "agent_3_agent_name_1_name_order" => "direct"
      )

      expect(report.rows[0].errors.join(" ")).to include("agent_3_header")
      expect(AgentPerson.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
    end

    [false, true].each do |validate_only|
      it "reports every bad Agent and Subject group and saves nothing from the row (validate-only: #{validate_only})" do
        original_people = AgentPerson.count
        original_subjects = Subject.count
        bad_role = "not-a-role-#{@now}"

        report = run_agent_import(
          person_group("agent_1_role" => bad_role).merge(
            "agent_2_agent_type" => "person",
            "agent_2_header" => "Valid Header Person #{@now}",
            "subject_1_term" => "Valid Subject #{@now}",
            "subject_1_type" => "topical",
            "subject_1_source" => "local",
            "subject_2_type" => "topical"
          ),
          validate_only
        )

        errors = report.rows[0].errors
        expect(errors.join(" ")).to include(bad_role)
        expect(errors).to include(I18n.t("bulk_import.error.subject_missing_identity", :num => "2"))
        expect(AgentPerson.count).to eq(original_people)
        expect(Subject.count).to eq(original_subjects)
        expect(digital_object_count).to eq(0)
      end
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

  context "matching an existing Agent from creation columns" do
    def colliding_group_three(overrides = {})
      {
        "agent_3_agent_type" => "person",
        "agent_3_agent_name_1_primary_name" => "Created Person #{@now}",
        "agent_3_agent_name_1_name_order" => "direct",
      }.merge(overrides)
    end

    def import_existing(overrides = {})
      run_agent_import(person_group(overrides).merge("digital_object_title" => "Existing Title #{@now}"))
      digital_object_titled("Existing Title #{@now}").linked_agents.first["ref"]
    end

    def expect_mismatch(report, uri, *named)
      errors = report.rows[0].errors.join(" ")
      expect(errors).to include(uri, *named)
      expect(errors).to include("link it by record ID or URI")
    end

    [false, true].each do |validate_only|
      it "links the existing Agent on a full fingerprint match and reports its URI (validate-only: #{validate_only})" do
        existing_uri = import_existing("agent_1_publish" => "true")
        original_count = AgentPerson.count

        report = run_agent_import(person_group("agent_1_publish" => "true"), validate_only)

        expect(report.rows[0].errors).to eq([])
        key = validate_only ? "bulk_import.agent_would_link_existing" : "bulk_import.agent_linked_existing"
        expect(report.rows[0].info).to include(I18n.t(key, :num => 1, :name => "Created Person #{@now}", :uri => existing_uri))
        expect(AgentPerson.count).to eq(original_count)
        expect(imported_digital_object.linked_agents.map { |link| link["ref"] }).to eq([existing_uri]) unless validate_only
      end

      it "fails the row when a fingerprint match differs in publish (validate-only: #{validate_only})" do
        existing_uri = import_existing("agent_1_publish" => "true")
        original_count = AgentPerson.count

        report = run_agent_import(person_group("agent_1_publish" => "false"), validate_only)

        expect_mismatch(report, existing_uri, "agent_1_publish", "false")
        expect(AgentPerson.count).to eq(original_count)
        expect(digital_object_count).to eq(0)
      end
    end

    it "links the existing Agent on an authority ID match with the same values" do
      authority = { "agent_1_agent_name_1_authority_id" => "same-#{@now}", "agent_1_agent_name_1_source" => "naf" }
      existing_uri = import_existing(authority)
      original_count = AgentPerson.count

      report = run_agent_import(person_group(authority))

      expect(report.rows[0].errors).to eq([])
      expect(AgentPerson.count).to eq(original_count)
      expect(imported_digital_object.linked_agents.map { |link| link["ref"] }).to eq([existing_uri])
    end

    it "fails the row when a sibling group matches the Agent created earlier in the row but differs in Sort Name" do
      original_count = AgentPerson.count

      report = run_agent_import(
        person_group.merge(colliding_group_three("agent_3_agent_name_1_sort_name" => "Custom Sort #{@now}"))
      )

      expect(report.rows[0].errors.join(" ")).to include("Agent 3", "agent_3_agent_name_1_sort_name", "Custom Sort #{@now}")
      expect(report.rows[0].errors.join(" ")).not_to include("sort_name_auto_generate")
      expect(AgentPerson.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
    end

    it "fails the row when a sibling group matches but differs only in nested telephone data" do
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

      expect(report.rows[0].errors.join(" ")).to include("Agent 3", "agent_3_agent_contact_1_telephone_1_number", "555-0199")
      expect(AgentPerson.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
    end

    it "fails the row when an authority ID match has a different name" do
      existing_uri = import_existing("agent_1_agent_name_1_authority_id" => "existing-#{@now}", "agent_1_agent_name_1_source" => "naf")
      original_count = AgentPerson.count

      [false, true].each do |validate_only|
        report = run_agent_import(
          person_group(
            "agent_1_agent_name_1_primary_name" => "Other Person #{@now}",
            "agent_1_agent_name_1_authority_id" => "existing-#{@now}",
            "agent_1_agent_name_1_source" => "naf"
          ),
          validate_only
        )

        expect_mismatch(report, existing_uri, "agent_1_agent_name_1_primary_name", "Other Person #{@now}")
      end
      expect(AgentPerson.count).to eq(original_count)
      expect(digital_object_count).to eq(0)
    end

    [false, true].each do |validate_only|
      it "fails the row without naming internal fields when an authority ID belongs to another Agent type (validate-only: #{validate_only})" do
        authority = { "agent_1_agent_name_1_authority_id" => "family-#{@now}", "agent_1_agent_name_1_source" => "naf" }
        run_agent_import(
          { "agent_1_agent_type" => "family", "agent_1_agent_name_1_primary_name" => "Existing Family #{@now}" }
            .merge(authority)
            .merge("digital_object_title" => "Existing Title #{@now}")
        )
        original_people = AgentPerson.count

        report = run_agent_import(person_group(authority), validate_only)

        errors = report.rows[0].errors.join(" ")
        expect(errors).to include(I18n.t("bulk_import.error.agent_authority_id_collision", :num => 1))
        expect(errors).not_to include("jsonmodel_type", "agent_person", "agent_family", "name_person", "name_family")
        expect(AgentPerson.count).to eq(original_people)
        expect(digital_object_count).to eq(0)
      end
    end

    [false, true].each do |validate_only|
      it "reports a schema-invalid creation Agent the same way in both modes (validate-only: #{validate_only})" do
        report = run_agent_import(person_group("agent_1_agent_name_1_primary_name" => "x" * 256), validate_only)

        expect(report.rows[0].errors.join(" ")).to include("Error processing Agent 1:", "primary_name")
        expect(digital_object_count).to eq(0)
      end
    end
  end

  context "the same creation Agent on several rows" do
    def row_titled(index, overrides = {})
      person_group(overrides).merge("digital_object_title" => "Row #{index} Title #{@now}")
    end

    it "creates one Agent and links it to both Digital Objects" do
      original_count = AgentPerson.count

      report = run_agent_import([row_titled(1), row_titled(2)])

      expect(report.rows.map(&:errors)).to eq([[], []])
      expect(AgentPerson.count).to eq(original_count + 1)
      first = digital_object_titled("Row 1 Title #{@now}").linked_agents.map { |link| link["ref"] }
      second = digital_object_titled("Row 2 Title #{@now}").linked_agents.map { |link| link["ref"] }
      expect(second).to eq(first)
      expect(report.rows[1].info).to include(I18n.t("bulk_import.agent_linked_existing", :num => 1, :name => "Created Person #{@now}", :uri => first.first))
    end

    it "predicts in validate-only mode that row 2 links the Agent row 1 would create" do
      report = run_agent_import([row_titled(1), row_titled(2)], true)

      expect(report.rows.map(&:errors)).to eq([[], []])
      expect(report.rows[1].info).to include(
        I18n.t("bulk_import.agent_would_link_earlier_row", :num => 1, :name => "Created Person #{@now}", :row => report.rows[0].row)
      )
    end

    [false, true].each do |validate_only|
      it "fails row 2 when it differs from row 1's Agent in publish (validate-only: #{validate_only})" do
        report = run_agent_import([row_titled(1, "agent_1_publish" => "true"), row_titled(2, "agent_1_publish" => "false")], validate_only)

        expect(report.rows[0].errors).to eq([])
        errors = report.rows[1].errors.join(" ")
        expect(errors).to include("agent_1_publish", "false")
        if validate_only
          expect(errors).to include(report.rows[0].row)
          expect(errors).not_to include("link it by record ID or URI")
        else
          expect(errors).to include("link it by record ID or URI")
        end
        expect(digital_object_count("Row 2 Title #{@now}")).to eq(0)
      end

      it "creates the Agent in row 2 when row 1 failed after creating it (validate-only: #{validate_only})" do
        original_count = AgentPerson.count

        report = run_agent_import([row_titled(1, "user_defined_integer_1" => "not-a-number"), row_titled(2)], validate_only)

        expect(report.rows[1].errors).to eq([])
        expect(report.rows[1].info.join(" ")).not_to include("link")
        expect(AgentPerson.count).to eq(original_count + (validate_only ? 0 : 1))
        unless validate_only
          agent_uri = digital_object_titled("Row 2 Title #{@now}").linked_agents.first["ref"]
          expect(JSONModel(:agent_person).find_by_uri(agent_uri).title).to eq("Created Person #{@now}")
        end
      end
    end

    it "creates one Agent for the same new Header String on two rows" do
      original_count = AgentPerson.count
      legacy = { "agent_1_agent_type" => "person", "agent_1_header" => "Legacy Shared #{@now}" }

      report = run_agent_import([
        legacy.merge("digital_object_title" => "Row 1 Title #{@now}"),
        legacy.merge("digital_object_title" => "Row 2 Title #{@now}"),
      ])

      expect(report.rows.map(&:errors)).to eq([[], []])
      expect(AgentPerson.count).to eq(original_count + 1)
    end

    it "reports an unexpected error while creating the Agent, fails that row, and imports the next row" do
      allow_any_instance_of(AgentHandler).to receive(:save).and_raise(RuntimeError, "boom #{@now}")
      original_count = AgentPerson.count

      report = run_agent_import([
        row_titled(1),
        { "digital_object_title" => "Row 2 Title #{@now}" },
      ])

      expect(report.rows[0].errors).to include(
        I18n.t("bulk_import.error.process_error", :type => I18n.t("bulk_import.agent"), :num => 1, :why => "boom #{@now}")
      )
      expect(AgentPerson.count).to eq(original_count)
      expect(digital_object_count("Row 1 Title #{@now}")).to eq(0)
      expect(report.rows[1].errors).to eq([])
      expect(digital_object_count("Row 2 Title #{@now}")).to eq(1)
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
        "agent_#{index}_agent_type" => "person",
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

  context "rolling back a row whose Digital Object is not created" do
    before(:each) do
      allow(ImportDigitalObjects).to receive(:new).and_wrap_original do |original, *args|
        @importer = original.call(*args)
      end
      @original_people = AgentPerson.count
      @original_subjects = Subject.count
    end

    def expect_row_rolled_back(report)
      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to include(I18n.t("bulk_import.error.dig_row_not_saved"))
      expect(report.rows[0].info).to eq([])
      expect(AgentPerson.count).to eq(@original_people)
      expect(@importer.record_uris).to eq([])
      expect(DigitalObject.where(:title => "Digital Object Title #{@now}").count).to eq(0)
    end

    it "saves no creation Agent when a later field raises" do
      report = run_agent_import(person_group("user_defined_integer_1" => "not-a-number"))

      expect(report.rows[0].errors.join(" ")).to include("not-a-number")
      expect_row_rolled_back(report)
    end

    it "saves no creation Agent when the Digital Object handler rejects a file version" do
      report = run_agent_import(
        person_group(
          "file_version_1_file_uri" => "http://example.org/#{@now}",
          "file_version_1_file_format_name" => "not-a-format-#{@now}"
        )
      )

      expect(report.rows[0].errors.join(" ")).to include("not-a-format-#{@now}")
      expect_row_rolled_back(report)
    end

    it "saves no Header String Agent and no Subject from a failed row" do
      report = run_agent_import(
        "agent_1_agent_type" => "person",
        "agent_1_header" => "Legacy Person #{@now}",
        "subject_1_term" => "Rolled Back Subject #{@now}",
        "subject_1_type" => "topical",
        "subject_1_source" => "local",
        "user_defined_integer_1" => "not-a-number"
      )

      expect_row_rolled_back(report)
      expect(Subject.count).to eq(@original_subjects)
    end

    it "creates and links the Agent when the corrected row is imported again" do
      run_agent_import(person_group("user_defined_integer_1" => "not-a-number"))

      report = run_agent_import(person_group)

      expect(report.terminal_error).to be_nil
      expect(report.rows[0].errors).to eq([])
      expect(AgentPerson.count).to eq(@original_people + 1)
      expect(linked_agent_records(imported_digital_object).map(&:title)).to eq(["Created Person #{@now}"])
    end

    it "reports a failed row in validate-only mode the same way as the real run" do
      report = run_agent_import(person_group("user_defined_integer_1" => "not-a-number"), true)

      errors = report.rows[0].errors
      expect(errors.join(" ")).to include("not-a-number")
      expect(errors).to include(I18n.t("bulk_import.object_not_created_be", :what => I18n.t("bulk_import.dig")))
      expect(errors.last).to eq(I18n.t("bulk_import.error.dig_row_not_saved"))
      expect(report.rows[0].info).to eq([])
      expect(AgentPerson.count).to eq(@original_people)
      expect(@importer.record_uris).to eq([])
    end

    it "keeps the Agent when an Event group fails after the Digital Object is linked" do
      report = run_agent_import(
        person_group(
          "event_1_type" => "processed",
          "event_1_date" => "2001-04-05",
          "event_1_outcome" => "pass",
          "event_1_outcome_note" => "n" * 16_385
        )
      )

      expect(report.rows[0].errors.join(" ")).to include(
        I18n.t("bulk_import.error.event_validation", :group => 1, :type => "processed", :err => "").strip
      )
      expect(report.rows[0].errors).not_to include(I18n.t("bulk_import.error.dig_row_not_saved"))
      expect(AgentPerson.count).to eq(@original_people + 1)
      expect(linked_agent_records(imported_digital_object).map(&:title)).to eq(["Created Person #{@now}"])
    end

    it "keeps the Digital Object and its Agent when the Archival Object cannot be saved" do
      allow_any_instance_of(ImportDigitalObjects).to receive(:ao_save).and_raise(BulkImportException.new("attach failed #{@now}"))

      report = run_agent_import(person_group)

      expect(report.rows[0].errors).to eq(
        [I18n.t("bulk_import.error.dig_unassoc", :msg => "attach failed #{@now}")]
      )
      expect(AgentPerson.count).to eq(@original_people + 1)
      expect(linked_agent_records(imported_digital_object).map(&:title)).to eq(["Created Person #{@now}"])
      expect(@importer.record_uris).to include(imported_digital_object.linked_agents.first["ref"])
    end
  end
end
