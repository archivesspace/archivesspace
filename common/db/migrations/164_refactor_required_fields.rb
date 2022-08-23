require_relative 'utils'
require 'json'

def convert_blob(old_blob, record_type)
  new_blob = {'lock_version' => 1}
  new_blob['record_type'] = record_type
  new_blob['subrecord_requirements'] = []
  old_blob.each do |property, defn|
    next unless defn.is_a?(Array)
    sr = {'property' => property}
    defn.each do |requirement|
      requirement.each do |field, value|
        next unless value == "REQ"
        sr['required_fields'] ||= []
        sr['required_fields'] << field
      end
    end
    new_blob['subrecord_requirements'] << sr
  end
  new_blob
end

Sequel.migration do
  up do
    self[:required_fields].each do |row|
      old_required_blob = JSON.parse(row[:blob])
      new_blob = convert_blob(old_required_blob['required'], row[:record_type])
      self[:required_fields].filter(:id => row[:id]).update(:blob => blobify(self, JSON.generate(new_blob)))
    end
  end
end
