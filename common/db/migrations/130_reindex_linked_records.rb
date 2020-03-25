require_relative 'utils'

Sequel.migration do

  up do
    $stderr.puts("Triggering a reindex of all archival records linked to subjects")

    ['accession', 'archival_object', 'resource', 'digital_object', 'digital_object_component'].each do |table|
      subject_rlshp = self[:subject_rlshp].exclude("#{table}_id": nil).map{|rlshp| rlshp[:"#{table}_id"]}.uniq
      subject_rlshp.each do |r|
        self[:"#{table}"].where(id: r).update(:system_mtime => Time.now)
      end
    end
  end


  down do
  end

end
