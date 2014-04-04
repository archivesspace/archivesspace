class LCNAFConverter < MarcXMLConverter

  def self.import_types(show_hidden = false)
    if show_hidden
      [
       {
         :name => "marcxml_lcnaf_subjects_and_agents",
         :description => "Import all subjects and agents from a MARC XML file, setting source to LCNAF"
       }
      ]
    else
      []
    end
  end


  def self.instance_for(type, input_file)
    if type == "marcxml_lcnaf_subjects_and_agents"
      self.for_subjects_and_agents_only(input_file)
    else
      nil
    end
  end


  def self.profile
    "Import all subjects and agents from a MARC XML file, setting source to LCNAF"
  end
end


LCNAFConverter.configure do |config|
  [
   "[@tag='720']['@ind1'='1']",
   "[@tag='720']['@ind1'='2']",
   "[@tag='100' or @tag='700'][@ind1='0' or @ind1='1']"
  ].each do |selector|
    config["/record"][:map]["datafield#{selector}"][:map]\
    ["self::datafield"][:defaults][:source] = 'naf'
  end
end
