class LCNAFAgentConverter < MarcXMLAuthAgentConverter

  def self.import_types(show_hidden = false)
    if show_hidden
      [
       {
         :name => "marcxml_lcnaf_agents",
         :description => "Import agents from a MARC XML file, setting source to LCNAF"
       }
      ]
    else
      []
    end
  end


  def self.instance_for(type, input_file)
    if type == "marcxml_lcnaf_agents"
      self.for_agents_only(input_file)
    else
      nil
    end
  end

end


LCNAFAgentConverter.configure do |config|
  config.init_map(MarcXMLAuthAgentConverter.BASE_RECORD_MAP(true, true))
end
