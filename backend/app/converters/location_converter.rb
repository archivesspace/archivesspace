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

  def self.instance_for(type, input_file)
    @import_options = {}
    new(input_file) if type == 'location_csv'
  end

  def set_import_options(opts)
    self.import_options&.merge!(opts)
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

      :location => {
        :on_create => Proc.new {|data, obj|
          if @import_options && @import_options[:import_repository]
            obj.owner_repo = {'ref' => JSONModel(:repository).uri_for(Thread.current[:request_context][:repo_id])}
          end
        }
      },
    }
  end
end
