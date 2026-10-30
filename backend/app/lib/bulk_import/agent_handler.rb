require_relative "handler"

require_relative "../../model/agent_person"
require_relative "../../model/agent_family"
require_relative "../../model/agent_corporate_entity"
require_relative "../../model/agent_software"
require_relative "bulk_import_mixins"

class AgentHandler < Handler
  AGENT_TYPES = { "families" => "family", "family" => "family", "corporate_entities" => "corporate_entity", "corporate_entity" => "corporate_entity", "people" => "person", "person" => "person" }

  def self.import_agent_types
    AGENT_TYPES.values.uniq
  end

  def self.import_agent_type(value, allowed = import_agent_types)
    type = value.to_s.strip.downcase
    type if allowed.include?(type)
  end

  def self.supplied_differences(supplied, existing, path = [])
    case supplied
    when Hash
      supplied.flat_map do |key, value|
        supplied_differences(value, existing.is_a?(Hash) ? existing[key] : nil, path + [key])
      end
    when Array
      supplied.each_with_index.flat_map do |value, index|
        supplied_differences(value, existing.is_a?(Array) ? existing[index] : nil, path + [index])
      end
    else
      supplied == existing ? [] : [{ :path => path, :supplied => supplied, :existing => existing }]
    end
  end

  def initialize(current_user, validate_only = false)
    super
    @agents = {}
    @would_create = {}
    @agent_role ||= CvList.new("linked_agent_role", @current_user)
    @agent_relators ||= CvList.new("linked_agent_archival_record_relators", @current_user)
  end

  def renew
    clear(@agent_relators)
    clear(@agent_role)
    @agents = {}
    @would_create = {}
  end

  def key_for(agent)
    key = "#{agent[:type]}_#{agent[:name]}"
    key
  end

  def build(type, id, header)
    {
      :type => AGENT_TYPES[type],
      :id => id,
      :name => header || (id ? I18n.t("bulk_import.unfound_id", :id => id, :type => "Agent") : nil),
      :id_but_no_name => id && !header,
    }
  end

  def get_agent_header(type, agent_obj)
    if type == "family"
      header = agent_obj.names[0]["family_name"]
    else
      header = agent_obj.names[0]["primary_name"]
    end
    header
  end

  def get_by_id(type, id)
    agent_obj = nil
    model = get_model(type)
    begin
      agent_obj = model.get_or_die(Integer(id))
      objs = model.sequel_to_jsonmodel([agent_obj])
      agent_obj = objs[0]
    rescue Exception => e
      if !e.message.end_with?(" not found")
        raise BulkImportException.new(I18n.t("bulk_import.error.no_create", :why => e.message))
      end
    end
    agent_obj
  end

  def get_or_create(type, id, header, relator, role, report, created_refs: nil)
    errs = []
    role = role || "creator"
    agent = build(type, id, header)
    agent_key = key_for(agent)
    agent_link = validate_link(relator, role, errs)
    report.add_errors(errs) if !errs.empty?
    if !(agent_obj = stored(@agents, (agent[:id].nil? ? "" : "#{agent[:type]}_#{agent[:id]}"), agent_key))
      unless agent[:id].nil?
        agent_obj = get_by_id(type, agent[:id])
      end
      begin
        if !agent_obj
          begin
            agent_obj = get_db_agent(agent, report)
          rescue Exception => e
            if e.message == "More than one match found in the database"
              disam = agent[:name] + DISAMB_STR
              report.add_info(I18n.t("bulk_import.warn.disam", :which => agent[:name], :name => disam))
              agent[:name] = disam
            else
              raise e
            end
          end
        end
        if !agent_obj
          agent_obj = create_agent(agent)
          created_refs << agent_obj.uri if created_refs && agent_obj.uri
          report.add_info(I18n.t(@create_key, :what => "#{I18n.t("bulk_import.agent")}[#{agent[:name]}]", :id => agent_obj.uri))
        end
      rescue Exception => e
        raise BulkImportException.new(I18n.t("bulk_import.error.no_create", :why => e.message))
      end
    end
    if agent_obj
      if agent[:id_but_no_name]
        agent_key = "#{agent[:type]}_#{get_agent_header(type, agent_obj)}"
        agent[:id_but_no_name] = nil
      end
      id = "#{agent[:type]}_#{agent[:id]}"
      remember(@agents, id, agent_obj)
      remember(@agents, agent_key, agent_obj)
      agent_link["ref"] = agent_obj.uri if agent_link
    end
    agent_link
  end

  def create_agent(agent)
    begin
      ret_agent = JSONModel("agent_#{agent[:type]}".to_sym).new._always_valid!
      ret_agent.names = [name_obj(agent)]
      ret_agent.publish = !(agent[:id_but_no_name] || agent[:name].end_with?(DISAMB_STR))
      model = get_model(agent[:type])
      ret_agent = save(ret_agent, model)
    rescue Exception => e
      raise Exception.new(I18n.t("bulk_import.error.no_create", :why => e.message))
    end
    ret_agent
  end

  def create_linked(agent, link, report, num, created_refs: nil, field_for: nil, supplied: agent)
    type = agent["jsonmodel_type"]
    model = get_model(type.delete_prefix("agent_"))
    json = JSONModel(type.to_sym).new(agent)
    model.ensure_authorized_name(json)
    json.to_hash

    pending_keys = @validate_only ? pending_keys(model, json) : []
    match = existing_match(model, json) || pending_keys.filter_map { |key| @would_create[key] }.first
    return link_match(match, supplied, link, report, num, field_for) if match

    saved = save(json, model)
    created_refs << saved.uri if created_refs && saved.uri
    pending = { :agent => agent, :name => display_name(agent), :row => report.current_row.row }
    pending_keys.each { |key| remember(@would_create, key, pending) }
    link["ref"] = saved.uri
    report.add_info(I18n.t(@create_key, :what => "#{I18n.t("bulk_import.agent")}[#{display_name(agent)}]", :id => saved.uri))
    link
  rescue JSONModel::ValidationException => e
    report_process_error(report, num, e.message)
  rescue Sequel::ValidationFailed => e
    key = collision_key(e)
    key ? report_collision(report, num, key) : report_process_error(report, num, e.message)
  rescue StandardError => e
    report_process_error(report, num, e.message)
  end

  def get_db_agent(agent, report)
    ret_ag = nil
    if agent[:id]
      ret_ag = get_by_id(agent[:type], agent[:id])
    end
    if !ret_ag
      a_params = { :q => "title:\"#{agent[:name]}\" AND primary_type:agent_#{agent[:type]}" }
      ret_ag = search(nil, a_params, "agent_#{agent[:type]}".to_sym, "", "title:#{agent[:name]}")
    end
    ret_ag
  end

  def get_model(type)
    return AgentSoftware if type == "software"

    model = nil
    case AGENT_TYPES[type]
    when "person"
      model = AgentPerson
    when "family"
      model = AgentFamily
    when "corporate_entity"
      model = AgentCorporateEntity
    end
    model
  end

  def name_obj(agent)
    obj = JSONModel("name_#{agent[:type]}".to_sym).new._always_valid!
    obj.source = "ingest"
    obj.authorized = true
    obj.is_display_name = true
    if agent[:type] == "family"
      obj.family_name = agent[:name]
    else
      obj.primary_name = agent[:name]
      obj.name_order = "direct" if agent[:type] == "person"
    end
    obj
  end

  def validate_link(relator, role, errs)
    link = {}
    link["role"] = value_check(@agent_role, role, errs)
    errs << I18n.t("bulk_import.error.bad_role", :label => role) if !link["role"]
    if relator && !relator.empty?
      link["relator"] = value_check(@agent_relators, relator, errs)
      errs << I18n.t("bulk_import.error.bad_relator", :label => relator) if !link["relator"]
    end
    if !errs.empty?
      link = nil
    end
    link
  end

  private

  def existing_match(model, json)
    existing = model.find_matching(json) || agent_holding_authority_id(json)
    return nil unless existing

    existing_json = existing.class.sequel_to_jsonmodel([existing])[0].to_hash(:trusted)
    { :agent => existing_json, :name => existing_json["title"], :uri => existing_json["uri"] }
  end

  def agent_holding_authority_id(json)
    authority_id = authority_id(json)
    authority = authority_id && NameAuthorityId.find(:authority_id => authority_id)
    return nil unless authority

    agent_type = AgentManager.registered_agents.find { |registered| authority[:"#{registered[:name_type]}_id"] }
    name = agent_type[:name_model][authority[:"#{agent_type[:name_type]}_id"]]
    agent_type[:model][name[:"#{agent_type[:jsonmodel]}_id"]]
  end

  def pending_keys(model, json)
    keys = ["sha1_#{model.calculate_hash(json)}"]
    authority_id = authority_id(json)
    keys << "authority_#{authority_id}" if authority_id
    keys
  end

  def authority_id(json)
    json["names"].map { |name| name["authority_id"] }.compact.first
  end

  def link_match(match, supplied, link, report, num, field_for)
    return report_collision(report, num, "agent_authority_id_collision") if match[:agent]["jsonmodel_type"] != supplied["jsonmodel_type"]

    differences = AgentHandler.supplied_differences(supplied, match[:agent])
    unless differences.empty?
      report.add_errors(mismatch_error(match, num, describe_differences(differences, field_for)))
      return nil
    end

    link["ref"] = match[:uri]
    report.add_info(match_info(match, num))
    link
  end

  def match_info(match, num)
    if match[:row]
      I18n.t("bulk_import.agent_would_link_earlier_row", :num => num, :name => match[:name], :row => match[:row])
    else
      key = @validate_only ? "bulk_import.agent_would_link_existing" : "bulk_import.agent_linked_existing"
      I18n.t(key, :num => num, :name => match[:name], :uri => match[:uri])
    end
  end

  def mismatch_error(match, num, differences)
    if match[:row]
      I18n.t("bulk_import.error.agent_match_mismatch_earlier_row", :num => num, :name => match[:name], :row => match[:row], :differences => differences)
    else
      I18n.t("bulk_import.error.agent_match_mismatch", :num => num, :name => match[:name], :where => match[:uri], :differences => differences)
    end
  end

  def describe_differences(differences, field_for)
    differences.map do |difference|
      path = difference[:path]
      I18n.t("bulk_import.error.agent_match_difference",
             :field => field_for&.call(path) || path.map { |step| step.is_a?(Integer) ? step + 1 : step }.join("/"),
             :supplied => difference[:supplied],
             :existing => difference[:existing])
    end.join("; ")
  end

  def display_name(agent)
    name = agent["names"][0]
    name["primary_name"] || name["family_name"]
  end

  def collision_key(error)
    if error.message.include?(AgentManager::AGENT_MUST_BE_UNIQUE)
      "agent_fingerprint_collision"
    elsif error.message.include?("Authority ID must be unique")
      "agent_authority_id_collision"
    end
  end

  def report_collision(report, num, key)
    report.add_errors(I18n.t("bulk_import.error.#{key}", :num => num))
    nil
  end

  def report_process_error(report, num, why)
    report.add_errors(I18n.t("bulk_import.error.process_error", :type => I18n.t("bulk_import.agent"), :num => num, :why => why))
    nil
  end
end # agent
