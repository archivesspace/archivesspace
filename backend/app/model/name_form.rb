class NameForm < Sequel::Model(:name_forms)
  include ASModel
  plugin :validation_helpers
  plugin :class_table_inheritance, :key => :kind, :table_map => { :PersonName => :person_names }
#  plugin :class_table_inheritance, :key => :kind, :table_map => { :PersonName => :person_names,
#    :FamilyName => :family_names, :CorporateEntityName => :corporate_entity_names, :SoftwareName => :software_names }

  many_to_one :agents

  def self.set_agent(json, opts)

    puts
    puts "in name_form.set_agent with:"
    puts "json: #{json}"
    puts "opts: #{opts}"

#    opts["agent_id"] = nil

    if json["agent"]
      opts["agent_id"] = JSONModel::parse_reference(json["agent"], opts)[:id]
    end
  end

  def self.create_from_json(json, opts = {})
#    set_agent(json, opts)
    super(json, opts)
  end

  def self.sequel_to_jsonmodel(obj, type)
    json = super(obj, type)
    json.agent = JSONModel(:agent).uri_for(obj.agent_id)

    json
  end


  def self.ensure_exists(json)
    begin
      self.create_from_json(json).id
    rescue Sequel::ValidationFailed
      NameForm.find(:vocab_id => JSONModel(:vocabulary).id_for(json.vocabulary),
                :term => json.term,
                :term_type => json.term_type).id
    end
  end

end
