require_relative 'spec_helper'

describe 'Structured Date model' do
  before :all do
    JSONModel::strict_mode(false)
  end

  it "creates valid label record with single date" do
    sd = build(:json_structured_date_label)
    errs = JSONModel::Validations.check_structured_date_label(sd)

    expect(errs.length > 0).to eq(false)
  end

  it "creates valid label record with range date" do
    sd = build(:json_structured_date_label_range)
    errs = JSONModel::Validations.check_structured_date_label(sd)

    expect(errs.length > 0).to eq(false)
  end

  it "label record is invalid without a date subrecord" do
    sd = build(:json_structured_date_label, :structured_date_single => nil)
    errs = JSONModel::Validations.check_structured_date_label(sd)

    expect(errs.length > 0).to eq(true)

  end

  it "label record is invalid if it has a single subrecord but type == range" do
    sd = build(:json_structured_date_label, :date_type_structured => "range")
    errs = JSONModel::Validations.check_structured_date_label(sd)

    expect(errs.length > 0).to eq(true)

  end

  it "label record is invalid if it has a range subrecord but type == single" do
    sd = build(:json_structured_date_label_range, :date_type_structured => "single")
    errs = JSONModel::Validations.check_structured_date_label(sd)

    expect(errs.length > 0).to eq(true)

  end

  it "label record is invalid both single and range subrecords are defined" do
    sdr = build(:json_structured_date_range)
    sd = build(:json_structured_date_label, :structured_date_range => sdr)
    errs = JSONModel::Validations.check_structured_date_label(sd)

    expect(errs.length > 0).to eq(true)

  end

  it "single dates are invalid unless a date is present in the subrecord" do
    sds = build(:json_structured_date_single, :date_expression => nil, :date_standardized => nil)
  
    errs = JSONModel::Validations.check_structured_date_single(sds)
    expect(errs.length > 0).to eq(true)
  end

  it "single dates are invalid if standardized dates do not fit format" do
    sds = build(:json_structured_date_single, :date_standardized => "Dec 12, 1928")
  
    errs = JSONModel::Validations.check_structured_date_single(sds)
    expect(errs.length > 0).to eq(true)
  end

  it "single dates are invalid if role is missing" do
    sds = build(:json_structured_date_single, :date_role => nil)
  
    errs = JSONModel::Validations.check_structured_date_single(sds)
    expect(errs.length > 0).to eq(true)
  end

  it "range dates are invalid if begin standardized dates do not fit format" do
    sdr = build(:json_structured_date_range, :begin_date_standardized => "Dec 12, 1928")
  
    errs = JSONModel::Validations.check_structured_date_range(sdr)
    expect(errs.length > 0).to eq(true)
  end

  it "range dates are invalid if end standardized dates do not fit format" do
    sdr = build(:json_structured_date_range, :end_date_standardized => "Dec 12, 1928")
  
    errs = JSONModel::Validations.check_structured_date_range(sdr)
    expect(errs.length > 0).to eq(true)
  end

  it "range dates are valid with just a begin date expression" do
    sdr = build(:json_structured_date_range, 
        :begin_date_expression => "Dec 12, 1928", 
        :begin_date_standardized => nil, 
        :end_date_expression => nil, 
        :end_date_standardized => nil)
  
    errs = JSONModel::Validations.check_structured_date_range(sdr)
    expect(errs.length > 0).to eq(false)
  end

  it "range dates are invalid if end expression present with no begin" do
    sdr = build(:json_structured_date_range, 
        :begin_date_expression => nil, 
        :begin_date_standardized => nil, 
        :end_date_expression => "Foo", 
        :end_date_standardized => nil)
  
    errs = JSONModel::Validations.check_structured_date_range(sdr)
    expect(errs.length > 0).to eq(true)
  end

  it "range dates are invalid if end standardized date present with no begin" do
    sdr = build(:json_structured_date_range, 
        :begin_date_expression => nil, 
        :begin_date_standardized => nil, 
        :end_date_expression => nil, 
        :end_date_standardized => "2001-01-01")
  
    errs = JSONModel::Validations.check_structured_date_range(sdr)
    expect(errs.length > 0).to eq(true)
  end

  it "range dates are invalid end date is after begin" do
    sdr = build(:json_structured_date_range, 
        :begin_date_expression => nil, 
        :begin_date_standardized => "2001-01-02", 
        :end_date_expression => nil, 
        :end_date_standardized => "2001-01-01")
  
    errs = JSONModel::Validations.check_structured_date_range(sdr)
    expect(errs.length > 0).to eq(true)
  end

  it "range dates are invalid end date is after begin for 4 digit dates" do
    sdr = build(:json_structured_date_range, 
        :begin_date_expression => nil, 
        :begin_date_standardized => "2002", 
        :end_date_expression => nil, 
        :end_date_standardized => "2001")
  
    errs = JSONModel::Validations.check_structured_date_range(sdr)
    expect(errs.length > 0).to eq(true)
  end

  describe "agent sort name updating from dates_of_existence" do
    it "adds a substring of the date to people agents sort name if a date of existence on date create" do
      agent = build(:json_agent_person_full_subrec) 
      agent.save

      ar = AgentPerson.to_jsonmodel(agent.id)

      year = ar["dates_of_existence"].first["structured_date_single"]["date_standardized"].split("-")[0]
 
      expect(ar["names"].first["sort_name"] =~ Regexp.new("#{year}")).to be_truthy
    end

    it "adds a substring of the date to people agents sort name if a date of existence on date update" do
      agent = build(:json_agent_person_full_subrec) 
      agent.save

      ar = AgentPerson.to_jsonmodel(agent.id)
      ar["dates_of_existence"].first["structured_date_single"]["date_standardized"] = nil
      ar["dates_of_existence"].first["structured_date_single"]["date_expression"] = "Last Year"

      ar.save

      expect(ar["names"].first["sort_name"] =~ /Last Year/).to be_truthy
    end

    it "adds a substring of the date to famly agents sort name if a date of existence on date create" do
      agent = build(:json_agent_family_full_subrec) 
      agent.save

      ar = AgentFamily.to_jsonmodel(agent.id)

      year = ar["dates_of_existence"].first["structured_date_single"]["date_standardized"].split("-")[0]
 
      expect(ar["names"].first["sort_name"] =~ Regexp.new("#{year}")).to be_truthy
    end

    it "adds a substring of the date to family agents sort name if a date of existence on date update" do
      agent = build(:json_agent_family_full_subrec) 
      agent.save

      ar = AgentFamily.to_jsonmodel(agent.id)
      ar["dates_of_existence"].first["structured_date_single"]["date_standardized"] = nil
      ar["dates_of_existence"].first["structured_date_single"]["date_expression"] = "Last Year"

      ar.save

      expect(ar["names"].first["sort_name"] =~ /Last Year/).to be_truthy
    end

    it "adds a substring of the date to corporate_entity agents sort name if a date of existence on date create" do
      agent = build(:json_agent_corporate_entity_full_subrec) 
      agent.save

      ar = AgentCorporateEntity.to_jsonmodel(agent.id)

      year = ar["dates_of_existence"].first["structured_date_single"]["date_standardized"].split("-")[0]
 
      expect(ar["names"].first["sort_name"] =~ Regexp.new("#{year}")).to be_truthy
    end

    it "adds a substring of the date to corporate_entity agents sort name if a date of existence on date update" do
      agent = build(:json_agent_corporate_entity_full_subrec) 
      agent.save

      ar = AgentCorporateEntity.to_jsonmodel(agent.id)
      ar["dates_of_existence"].first["structured_date_single"]["date_standardized"] = nil
      ar["dates_of_existence"].first["structured_date_single"]["date_expression"] = "Last Year"

      ar.save

      expect(ar["names"].first["sort_name"] =~ /Last Year/).to be_truthy
    end

    it "adds a substring of the date to software agents sort name if a date of existence on date create" do
      agent = build(:json_agent_software_full_subrec) 
      agent.save

      ar = AgentSoftware.to_jsonmodel(agent.id)

      year = ar["dates_of_existence"].first["structured_date_single"]["date_standardized"].split("-")[0]
 
      expect(ar["names"].first["sort_name"] =~ Regexp.new("#{year}")).to be_truthy
    end

    it "adds a substring of the date to software agents sort name if a date of existence on date update" do
      agent = build(:json_agent_software_full_subrec) 
      agent.save

      ar = AgentSoftware.to_jsonmodel(agent.id)
      ar["dates_of_existence"].first["structured_date_single"]["date_standardized"] = nil
      ar["dates_of_existence"].first["structured_date_single"]["date_expression"] = "Last Year"

      ar.save

      expect(ar["names"].first["sort_name"] =~ /Last Year/).to be_truthy
    end

    it "adds a substring of all dates to an agent's sortname on date create" do
      dates = [build(:json_structured_date_label), 
               build(:json_structured_date_label)]
      agent = build(:json_agent_software_full_subrec, :dates_of_existence => dates) 
      agent.save

      ar = AgentSoftware.to_jsonmodel(agent.id)
      year1 = ar["dates_of_existence"][0]["structured_date_single"]["date_standardized"].split("-")[0]
      year2 = ar["dates_of_existence"][1]["structured_date_single"]["date_standardized"].split("-")[0]

      expect(ar["names"].first["sort_name"] =~ Regexp.new("#{year1}")).to be_truthy
      expect(ar["names"].first["sort_name"] =~ Regexp.new("#{year2}")).to be_truthy
    end

    it "adds a substring of all dates to an agent's sortname on date update" do
      dates = [build(:json_structured_date_label), 
               build(:json_structured_date_label)]
      agent = build(:json_agent_software_full_subrec, :dates_of_existence => dates) 
      agent.save

      ar = AgentSoftware.to_jsonmodel(agent.id)
      ar["dates_of_existence"][0]["structured_date_single"]["date_standardized"] = nil
      ar["dates_of_existence"][0]["structured_date_single"]["date_expression"] = "Last Year"
      ar["dates_of_existence"][1]["structured_date_single"]["date_standardized"] = nil
      ar["dates_of_existence"][1]["structured_date_single"]["date_expression"] = "This Weekend"

      ar.save

      expect(ar["names"].first["sort_name"] =~ /Last Year/).to be_truthy
      expect(ar["names"].first["sort_name"] =~ /This Weekend/).to be_truthy
    end
  end
end
