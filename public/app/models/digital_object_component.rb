class DigitalObjectComponent < DigitalObject
  include TreeNodes

  def root_node_uri
    json.fetch('digital_object').fetch('ref')
  end

  def parse_identifier
    json['component_id']
  end

end
