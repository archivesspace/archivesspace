require_relative 'utils'

Sequel.migration do

  up do

    $stderr.puts("Adding updated ISO 639-2 language codes as of 2018-11-30")
    enum = self[:enumeration].filter(:name => 'language_iso639_2').select(:id)
    cnr = self[:enumeration_value].filter(:value => 'cnr', :enumeration_id => enum ).select(:id).all
    zgh = self[:enumeration_value].filter(:value => 'zgh', :enumeration_id => enum ).select(:id).all
    if cnr.length == 0
      position = self[:enumeration_value].filter(
        enumeration_id: enum
      ).max(:position) + 1
      $stderr.puts("Adding Montenegrin")
      self[:enumeration_value].insert(:enumeration_id => enum, :value => "cnr", :position => position)
    end
    if zgh.length == 0
      position = self[:enumeration_value].filter(
        enumeration_id: enum
      ).max(:position) + 1
      $stderr.puts("Adding Standard Moroccan Tamazight")
      self[:enumeration_value].insert(:enumeration_id => enum, :value => "zgh", :position => position)
    end

  end

end
