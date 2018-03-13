require_relative 'utils'

Sequel.migration do

  up do

    qaa = self[:enumeration_value].filter(:value => 'qaa-qtz').select(:id)
    und = self[:enumeration_value].filter(:value => 'und').select(:id)
    $stderr.puts("Updating #{qaa.to_s} to #{und.to_s}")
    self[:resource].where(:language_id => qaa).update(:language_id => und)
    $stderr.puts("Deleting enumeration_id #{qaa.to_s}")
    self[:enumeration_value].where(qaa.all).delete

  end

end
