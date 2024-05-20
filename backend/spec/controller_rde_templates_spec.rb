require 'spec_helper'

describe "RDE Templates" do

  let(:hash) {
    ->(name) {
      {
        "record_type" => "archival_object",
        "name" => name,
        "order" => ["colStatus", "colLevel", "colOtherLevel", "colPublish", "colTitle", "colCompId", "colLang", "colExpr", "colDType", "colDBegin", "colDEnd", "colIType", "colCType1", "colCInd1", "colCBarc1", "colCType2", "colCInd2", "colCType3", "colCInd3", "colNType1", "colNCont1", "colNType2", "colNCont2", "colNType3", "colNCont3", "colActions"],
        "visible" => ["colLevel", "colOtherLevel", "colTitle", "colCompId", "colLang", "colExpr", "colDType", "colDBegin", "colDEnd", "colIType", "colCType1", "colCInd1", "colCBarc1", "colCType2", "colCInd2", "colCType3", "colCInd3", "colNType1", "colNCont1", "colNType2", "colNCont2", "colNType3", "colNCont3"],
        "defaults" => {
          "colTitle" => "DEFAULT TITLE",
          "colLevel" => "item"
        }
      }
    }
  }


  it "can create an RDE Template and get it back" do
    template = JSONModel(:rde_template)
      .from_hash(hash['MY TEMPLATE'])


    id = template.save
    obj = JSONModel(:rde_template).find(id)

    expect(obj.defaults['colTitle']).to eq('DEFAULT TITLE')
    expect(obj.name).to eq('MY TEMPLATE')

  end


  it "can give a list of all templates" do
    %w(one two three).map {|name| JSONModel(:rde_template).from_hash(hash[name]).save}

    templates = JSONModel(:rde_template).all

    %w(one two three).each do |name|
      expect(templates.any? {|res| res.name == name}).to be_truthy
    end

  end
end
