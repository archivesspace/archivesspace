require_relative 'utils'
require 'json'

Sequel.migration do
  up do
    self[:rde_template].each do |template|
      RDETemplateFix::CONFIG[:field_updates].each do |field, type|
        obj = JSON.parse(template[field])
        did_something = RDETemplateFix.send(type, obj)
        next unless did_something

        self[:rde_template].where(id: template[:id]).update(field => JSON.generate(obj))
      end
    end
  end

  down do
    # We ain't going back!
  end
end
