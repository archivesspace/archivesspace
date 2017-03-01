class DigitalObjectComponent < DigitalObject

  def root_node_uri
    json.fetch('digital_object').fetch('ref')
  end

end
