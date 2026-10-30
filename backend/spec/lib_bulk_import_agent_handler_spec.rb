require "spec_helper"
require_relative "../app/lib/bulk_import/agent_handler"
require_relative "../app/model/mixins/dynamic_enums"
require_relative "../app/model/enumeration"

describe "Agent Handler" do
  # define some agents by type
  let(:person_agent) {
    build(:json_agent_person,
          :names => [build(:json_name_person)],
          :agent_contacts => [build(:json_agent_contact)],
          :external_documents => [build(:json_external_document)],
          :notes => [build(:json_note_bioghist)])
  }
  test_opts = { :names => [
    {
      "rules" => "local",
      "family_name" => "Magoo Family",
      "sort_name" => "Family Magoo",
    },
  ] }

  let(:family_agent) {
    build(:json_agent_family, test_opts)
  }
  test_opts1 = { :names => [
    {
      "rules" => "local",
      "primary_name" => "Magus Magoo Inc",
      "sort_name" => "Magus Magoo Inc",
    },
  ] }
  let(:corp_agent) {
    build(:json_agent_corporate_entity, test_opts1)
  }

  before(:each) do
    current_user = User.find(:username => "admin")
    @ah = AgentHandler.new(current_user)
    @ahv = AgentHandler.new(current_user, true)
    @agents = @ah.instance_variable_get(:@agents)
    @report = BulkImportReport.new
    @report.new_row(1)
  end

  def build_return_key(type, id, header)
    agent = @ah.build(type, id, header)
    { agent: agent,
      key: @ah.key_for(agent) }
  end

  it "should build an agents hash and return a key" do
    res = build_return_key("people", nil, "Smith, John")
    expect(res[:key]).to eq("person_Smith, John")
  end

  it "should validate the agent link" do
    errs = []
    res = @ah.validate_link("aut", "creator", errs)
    expect(res.nil?).to be(false)
    expect(errs.empty?).to be(true)
  end

  it "should fail to validate the agent link" do
    errs = []
    res = @ah.validate_link("xxx", "creator", errs)
    expect(errs.empty?).to be(false)
    aggregate_failures do
      expect(errs[0]).to eq("INVALID: linked_agent_archival_record_relators: 'xxx'. Must be one of: acp, act, adp, aft, anl, anm, ann, ant, app, aqt, arc, ard, arr, art, asg, asn, att, auc, aud, aui, aus, aut, bdd, bjd, bkd, bkp, blw, bnd, bpd, bsl, ccp, chr, clb, cli, cll, clr, clt, cmm, cmp, cmt, cnd, cng, cns, coe, col, com, con, cos, cot, cov, cpc, cpe, cph, cpl, cpt, cre, crp, crr, csl, csp, cst, ctb, cte, ctg, ctr, cts, ctt, cur, cwt, dbp, dfd, dfe, dft, dgg, dis, dln, dnc, dnr, dpc, dpt, drm, drt, dsr, dst, dtc, dte, dtm, dto, dub, edt, egr, elg, elt, eng, etr, evp, exp, fac, fld, flm, fmo, fnd, fpy, frg, gis, grt, hnr, hst, ill, ilu, ins, inv, itr, ive, ivr, lbr, lbt, ldr, led, lee, lel, len, let, lgd, lie, lil, lit, lsa, lse, lso, ltg, lyr, mcp, mdc, mfp, mfr, mod, mon, mrb, mrk, msd, mte, mus, nrt, opn, org, orm, oth, own, pat, pbd, pbl, pdr, pfr, pht, plt, pma, pmn, pop, ppm, ppt, prc, prd, prf, prg, prm, pro, prp, prt, prv, pta, pte, ptf, pth, ptt, pup, rbr, rcd, rce, rcp, red, ren, res, rev, rps, rpt, rpy, rse, rsg, rsp, rst, rth, rtm, sad, sce, scl, scr, sds, sec, sgn, sht, sng, spk, spn, spy, srv, std, stg, stl, stm, stn, str, tcd, tch, ths, trc, trl, tyd, tyg, uvp, vdg, voc, wam, wdc, wde, wit, abr, adi, ape, apl, ato, brd, brl, cas, cor, cou, crt, dgs, edc, edm, enj, fds, fmd, fmk, fmp, -grt, his, isb, jud, jug, med, mtk, osp, pan, pra, pre, prn, prs, rdd, rpc, rsr, sgd, sll, tld, tlp, vac, wac, wal, wat, win, wpr, wst")
      expect(errs[1]).to start_with("Unable to create")
    end
  end

  it "should build an agent entry  with the 'id_but_no_name' value as true " do
    agent = @ah.build("people", 20, nil)
    expect(agent[:id_but_no_name]).to eq(true)
  end

  it "should validate an agent/link without creating it" do
    res = build_return_key("people", nil, "Doe, Jane, Jr.")
    created = nil
    expect {
      created = @ahv.create_agent(res[:agent])
    }.not_to raise_error
    expect(created.nil?).to be(false)
    expect(@report.current_row.errors.empty?).to be(true)
  end

  it "should validate that an agent link can be created with no relator data" do
    agent_1 = AgentFamily.create_from_json(family_agent)
    expect {
      ag = @ahv.get_or_create("family", agent_1[:id], "Magoo Family", nil, nil, @report)
    }.not_to raise_error
  end

  it "should validate that an agent link can't be created with bad relator data" do
    agent_1 = AgentFamily.create_from_json(family_agent)
    expect {
      ag = @ahv.get_or_create("family", agent_1[:id], "Magoo Family", nil, "this_is_not_a_real_relator", @report)
    }.not_to raise_error
    aggregate_failures do
      expect(@report.current_row.errors[0]).to eq("INVALID: linked_agent_role: 'this_is_not_a_real_relator'. Must be one of: creator, source, subject")
      expect(@report.current_row.errors[1]).to start_with("Unable to create agent link")
    end
  end

  it "should validate that an agent link can't be created with bad role or relator data" do
    agent_1 = AgentFamily.create_from_json(family_agent)
    expect {
      ag = @ahv.get_or_create("family", agent_1[:id], "Magoo Family", "AUthor", "xxx", @report)
    }.not_to raise_error

    aggregate_failures do
      expect(@report.current_row.errors[0]).to eq("INVALID: linked_agent_role: 'xxx'. Must be one of: creator, source, subject")
      expect(@report.current_row.errors[1]).to start_with("Unable to create agent link")
      expect(@report.current_row.errors[2]).to eq("INVALID: linked_agent_archival_record_relators: 'AUthor'. Must be one of: acp, act, adp, aft, anl, anm, ann, ant, app, aqt, arc, ard, arr, art, asg, asn, att, auc, aud, aui, aus, aut, bdd, bjd, bkd, bkp, blw, bnd, bpd, bsl, ccp, chr, clb, cli, cll, clr, clt, cmm, cmp, cmt, cnd, cng, cns, coe, col, com, con, cos, cot, cov, cpc, cpe, cph, cpl, cpt, cre, crp, crr, csl, csp, cst, ctb, cte, ctg, ctr, cts, ctt, cur, cwt, dbp, dfd, dfe, dft, dgg, dis, dln, dnc, dnr, dpc, dpt, drm, drt, dsr, dst, dtc, dte, dtm, dto, dub, edt, egr, elg, elt, eng, etr, evp, exp, fac, fld, flm, fmo, fnd, fpy, frg, gis, grt, hnr, hst, ill, ilu, ins, inv, itr, ive, ivr, lbr, lbt, ldr, led, lee, lel, len, let, lgd, lie, lil, lit, lsa, lse, lso, ltg, lyr, mcp, mdc, mfp, mfr, mod, mon, mrb, mrk, msd, mte, mus, nrt, opn, org, orm, oth, own, pat, pbd, pbl, pdr, pfr, pht, plt, pma, pmn, pop, ppm, ppt, prc, prd, prf, prg, prm, pro, prp, prt, prv, pta, pte, ptf, pth, ptt, pup, rbr, rcd, rce, rcp, red, ren, res, rev, rps, rpt, rpy, rse, rsg, rsp, rst, rth, rtm, sad, sce, scl, scr, sds, sec, sgn, sht, sng, spk, spn, spy, srv, std, stg, stl, stm, stn, str, tcd, tch, ths, trc, trl, tyd, tyg, uvp, vdg, voc, wam, wdc, wde, wit, abr, adi, ape, apl, ato, brd, brl, cas, cor, cou, crt, dgs, edc, edm, enj, fds, fmd, fmk, fmp, -grt, his, isb, jud, jug, med, mtk, osp, pan, pra, pre, prn, prs, rdd, rpc, rsr, sgd, sll, tld, tlp, vac, wac, wal, wat, win, wpr, wst")
      expect(@report.current_row.errors[3]).to start_with("Unable to create agent link")
    end
  end

  it "should create an person agent using 'create_agent', then retrieve an agent link with 'get_or_create'" do
    res = build_return_key("people", nil, "Smith, John")
    created = @ah.create_agent(res[:agent])
    id = created[:id]
    a = nil
    expect {
      a = AgentPerson.get_or_die(id)
    }.not_to raise_error
    expect(a[:id]).to eq(id)
    a1 = @ah.get_or_create("people", id, nil, "aut", "source", @report)
    newid = a1["ref"].split("/")[3]
    expect(newid).to eq(id.to_s)
    a.delete
  end

  it "should find a person agent from its ID " do
    agent_1 = AgentPerson.create_from_json(person_agent)
    a1 = @ah.get_or_create("people", agent_1[:id], nil, "aut", "source", @report)
    newid = a1["ref"].split("/")[3]
    expect(newid).to eq(agent_1[:id].to_s)
    agent_1.delete
  end
  it "should find a family from its ID" do
    agent_2 = AgentFamily.create_from_json(family_agent)
    a1 = @ah.get_or_create("family", agent_2[:id], nil, "aut", "source", @report)
    newid = a1["ref"].split("/")[3]
    expect(newid).to eq(agent_2[:id].to_s)
  end
  it "should find a corporation from its ID" do
    agent_3 = AgentCorporateEntity.create_from_json(corp_agent)
    a1 = @ah.get_or_create("corporate_entity", agent_3[:id], nil, "aut", nil, @report)
    newid = a1["ref"].split("/")[3]
    expect(newid).to eq(agent_3[:id].to_s)
  end

  describe "create_linked" do
    def built_agent(type, name)
      name_type = type.sub("agent_", "name_")
      name_fields = type == "agent_family" ? { "family_name" => name } : { "primary_name" => name, "name_order" => "direct" }
      { "jsonmodel_type" => type,
        "names" => [{ "jsonmodel_type" => name_type, "rules" => "local", "authorized" => true, "is_display_name" => true }.merge(name_fields)] }
    end

    def row_info
      @report.new_row(2)
      @report.rows[0].info
    end

    it "reports a created person Agent by its primary name and URI" do
      link = @ah.create_linked(built_agent("agent_person", "Created Person #{rand(1_000_000)}"), { "role" => "creator" }, @report, 1)

      expect(row_info[0]).to match(%r{\AAgent\[Created Person \d+\] created: #{Regexp.escape(link['ref'])}\z})
      expect(link["ref"]).to match(%r{\A/agents/people/\d+\z})
    end

    it "reports a created family Agent by its family name" do
      @ah.create_linked(built_agent("agent_family", "Created Family #{rand(1_000_000)}"), { "role" => "creator" }, @report, 1)

      expect(row_info[0]).to match(%r{\AAgent\[Created Family \d+\] created: /agents/families/\d+\z})
    end

    it "reports that an Agent would be created in validate-only mode, saving nothing" do
      before_count = AgentPerson.count
      @ahv.create_linked(built_agent("agent_person", "Preview Person #{rand(1_000_000)}"), { "role" => "creator" }, @report, 1)

      expect(row_info[0]).to match(/\AAgent\[Preview Person \d+\] would be created\z/)
      expect(AgentPerson.count).to eq(before_count)
    end

    it "reports a schema-invalid Agent the same way in validate-only mode as in a real run" do
      reports = [@ah, @ahv].map do |handler|
        report = BulkImportReport.new
        report.new_row(1)
        expect(handler.create_linked(built_agent("agent_person", "x" * 256), { "role" => "creator" }, report, 1)).to be_nil
        report.current_row.errors
      end

      expect(reports[0]).not_to be_empty
      expect(reports[1]).to eq(reports[0])
    end

    it "links an existing Agent whose supplied values all match, in both modes" do
      name = "Matched Person #{rand(1_000_000)}"
      existing = @ah.create_linked(built_agent("agent_person", name), { "role" => "creator" }, @report, 1)
      before_count = AgentPerson.count

      [[@ah, "bulk_import.agent_linked_existing"], [@ahv, "bulk_import.agent_would_link_existing"]].each do |handler, key|
        report = BulkImportReport.new
        report.new_row(2)
        link = handler.create_linked(built_agent("agent_person", name), { "role" => "creator" }, report, 1)

        expect(link["ref"]).to eq(existing["ref"])
        expect(report.current_row.info).to eq([I18n.t(key, :num => 1, :name => name, :uri => existing["ref"])])
      end
      expect(AgentPerson.count).to eq(before_count)
    end

    it "reports a match whose publish value differs, naming the value and the existing URI" do
      name = "Mismatched Person #{rand(1_000_000)}"
      existing = @ah.create_linked(built_agent("agent_person", name).merge("publish" => true), { "role" => "creator" }, @report, 1)
      report = BulkImportReport.new
      report.new_row(2)

      link = @ah.create_linked(built_agent("agent_person", name).merge("publish" => false), { "role" => "creator" }, report, 1)

      expect(link).to be_nil
      expect(report.current_row.errors.join(" ")).to include(existing["ref"], "publish", "false", "true")
    end

    it "remembers an Agent validate-only would create until the row is forgotten" do
      name = "Pending Person #{rand(1_000_000)}"
      @ahv.start_row
      @ahv.create_linked(built_agent("agent_person", name), { "role" => "creator" }, @report, 1)

      report = BulkImportReport.new
      report.new_row(2)
      @ahv.create_linked(built_agent("agent_person", name), { "role" => "creator" }, report, 1)
      expect(report.current_row.info).to eq([I18n.t("bulk_import.agent_would_link_earlier_row", :num => 1, :name => name, :row => @report.current_row.row)])

      @ahv.forget_row
      report = BulkImportReport.new
      report.new_row(3)
      @ahv.create_linked(built_agent("agent_person", name), { "role" => "creator" }, report, 1)
      expect(report.current_row.info.first).to match(/would be created\z/)
    end

    it "reports an unexpected error while saving and returns nil" do
      allow(@ah).to receive(:save).and_raise(RuntimeError, "unexpected failure")

      link = nil
      expect {
        link = @ah.create_linked(built_agent("agent_person", "Failing Person"), { "role" => "creator" }, @report, 1)
      }.not_to raise_error

      expect(link).to be_nil
      expect(@report.current_row.errors).to eq(["Error processing Agent 1: unexpected failure"])
    end
  end

  describe "supplied_differences" do
    it "finds no differences when every supplied value matches" do
      supplied = { "publish" => true, "names" => [{ "primary_name" => "Smith" }] }
      existing = { "publish" => true, "title" => "Smith", "names" => [{ "primary_name" => "Smith", "sort_name" => "Smith" }] }

      expect(AgentHandler.supplied_differences(supplied, existing)).to eq([])
    end

    it "ignores values only the existing record has" do
      expect(AgentHandler.supplied_differences({ "names" => [{}] }, { "names" => [{ "a" => 1 }, { "b" => 2 }] })).to eq([])
    end

    it "reports each differing value with its path, supplied value and existing value" do
      supplied = { "publish" => false, "agent_contacts" => [{ "telephones" => [{ "number" => "555-0199" }] }] }
      existing = { "publish" => true, "agent_contacts" => [{ "telephones" => [{ "number" => "555-0100" }] }] }

      expect(AgentHandler.supplied_differences(supplied, existing)).to eq([
        { :path => ["publish"], :supplied => false, :existing => true },
        { :path => ["agent_contacts", 0, "telephones", 0, "number"], :supplied => "555-0199", :existing => "555-0100" },
      ])
    end

    it "reports a supplied value the existing record lacks" do
      expect(AgentHandler.supplied_differences({ "notes" => [{ "content" => ["x"] }] }, { "notes" => [] })).to eq([
        { :path => ["notes", 0, "content", 0], :supplied => "x", :existing => nil },
      ])
    end
  end
end
