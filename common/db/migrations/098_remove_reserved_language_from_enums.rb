require_relative 'utils'

Sequel.migration do

  up do

    qaa = self[:enumeration_value].filter(:value => 'qaa-qtz').select(:id)
    und = self[:enumeration_value].filter(:value => 'und').select(:id)
    $stderr.puts("Updating #{qaa.to_s} to #{und.to_s}")
    self[:resource].where(:language_id => qaa).update(:language_id => und)
    $stderr.puts("Deleting enumeration_id #{qaa.to_s}")
    self[:enumeration_value].where(qaa.all).delete

    # trigger reindex of record types that may have this language_iso639_2 field populated
    [:resource, :archival_object, :digital_object, :digital_object_component ].each do |klass|
      $stderr.puts("Triggering reindex of #{klass.to_s}")
      self[klass ].update(:system_mtime => Time.now)
    end

  end

end
