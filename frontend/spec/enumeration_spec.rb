require 'rails'
require_relative 'spec_helper'

I18n.load_path += ASUtils.find_locales_directories(File.join("enums", "#{AppConfig[:locale]}.yml"))

describe "Frontend enumerations" do

  def tree_search(obj, predicate)
    if predicate.call(obj)
      [obj]
    elsif obj.is_a?(Array)
      obj.map {|elt| tree_search(elt, predicate)}.flatten(1)
    elsif obj.is_a?(Hash)
      obj.values.map {|elt| tree_search(elt, predicate)}.flatten(1)
    else
      []
    end
  end


  def dynamic_enums_used_by(model)
    properties = tree_search(model.schema['properties'],
                             proc {|obj| obj.is_a?(Hash) && obj['dynamic_enum']})
    properties.map {|property| property['dynamic_enum']}
  end


  it "has a translation for each dynamic enumeration" do
    all_dynamic_enums = JSONModel.models.map {|name, model| dynamic_enums_used_by(model) }.flatten.uniq
    missing_translations = all_dynamic_enums.select {|enum|
      I18n.t("enumeration_names.#{enum}") =~ /translation missing/
    }

    missing_translations.should eq([])
  end

end
