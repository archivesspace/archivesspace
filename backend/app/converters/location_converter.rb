require_relative 'converter'
class LocationConverter < Converter

  require_relative 'lib/csv_converter'
  include ASpaceImport::CSVConvert

  def self.import_types(show_hidden = false)
    [
      {
        name: 'location_csv',
        description: 'Import Location records from a CSV file',
      }
    ]
  end

  def self.instance_for(type, input_file, opts = {})
    new(input_file) if type == 'location_csv'
  end

  def self.configure
    {
      'location_building' => 'location.building',
      'location_floor' => 'location.floor',
      'location_room' => 'location.room',
      'location_area' => 'location.area',
      'location_barcode' => 'location.barcode',
      'location_classification' => 'location.classification',
      'location_coordinate_1_label' => 'location.coordinate_1_label',
      'location_coordinate_1_indicator' => 'location.coordinate_1_indicator',
      'location_coordinate_2_label' => 'location.coordinate_2_label',
      'location_coordinate_2_indicator' => 'location.coordinate_2_indicator',
      'location_coordinate_3_label' => 'location.coordinate_3_label',
      'location_coordinate_3_indicator' => 'location.coordinate_3_indicator',
      'location_temporary' => 'location.temporary',
    }
  end
end
