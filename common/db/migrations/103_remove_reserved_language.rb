require_relative 'utils'

Sequel.migration do

  up do

    qaa = self[:enumeration_value].filter(:value => 'qaa-qtz').select(:id)
    und = self[:enumeration_value].filter(:value => 'und').select(:id)
    $stderr.puts("Updating qaa-qtz to und")
    self[:resource].where(:language_id => qaa).update(:language_id => und)
    self[:archival_object].where(:language_id => qaa).update(:language_id => und)
    self[:digital_object].where(:language_id => qaa).update(:language_id => und)
    self[:digital_object_component].where(:language_id => qaa).update(:language_id => und)
    $stderr.puts("Deleting enumeration_id for qaa-qtz")
    self[:enumeration_value].filter(:value => 'qaa-qtz').delete

  end

end
