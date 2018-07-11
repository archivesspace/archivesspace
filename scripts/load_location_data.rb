#!/bin/bash
#
# Run with ./scripts/load_location_data.rb

"exec" "`dirname $0`/jruby" "$0" "$@"

$: << File.join(File.dirname(__FILE__), "..", "common")

# Number of locations to generate
BUILDING_COUNT = 100
LOCATIONS_PER_BUILDING = 5

SAMPLE_LOCATION_PROFILES = [
  {:name => 'record carton shelf (Remarque)', :depth => '15.5', :height => '10.75', :width => '39.25'},
  {:name => 'oversize - short - TAM', :depth => '31.75', :height => '6.5', :width => '39.5'},
  {:name => 'oversize - short - TAM 2', :depth => '31.5', :height => '6.5', :width => '27.5'},
  {:name => '2 deep - 3 wide - 1 high', :depth => '31.75', :height => '11.75', :width => '39.5'},
  {:name => '2 deep - 3 wide - 2 high', :depth => '31.75', :height => '22.75', :width => '39.5'},
  {:name => 'oversize - short', :depth => '41.5', :height => '10.75', :width => '29.25'},
  {:name => 'cd shelf 1', :depth => '7', :height => '11', :width => '41.5'},
  {:name => 'cd shelf 2', :depth => '8.5', :height => '12', :width => '29.5'},
  {:name => 'Fales Media Storage 1', :depth => '15', :height => '16.75', :width => '34'},
  {:name => 'Fales Media Storage 2', :depth => '15', :height => '12.75', :width => '34'},
  {:name => 'map case 2', :depth => '38', :height => '1.75', :width => '50'},
  {:name => 'map case 3', :depth => '40.5', :height => '0.75', :width => '49.5'},
  {:name => 'CSQ standard compact shelf', :depth => '15.5', :height => '11', :width => '27.75'},
  {:name => 'CSQ extra high compact shelf with set back', :depth => '15.5', :height => '17.25', :width => '27.75'},
  {:name => 'CSQ extra high compact shelf with no set back', :depth => '15.5', :height => '17.25', :width => '27.75'},
  {:name => 'UA Shelving (varies)', :depth => '15', :height => '12', :width => '35.5'},
  {:name => 'Fales 10W - 2 wide', :depth => '15.5', :height => '11.25', :width => '27.75'},
]

SAMPLE_CONTAINER_PROFILES = [
  {:name => 'Paige 15', :depth => '15.5', :height => '10.5', :width => '13', :dimension_units => 'inches', :extent_dimension => 'width'},
  {:name => 'archive legal', :depth => '15.5', :height => '10.25', :width => '5', :dimension_units => 'inches', :extent_dimension => 'width'},
  {:name => 'archive letter', :depth => '12.5', :height => '10.25', :width => '5', :dimension_units => 'inches', :extent_dimension => 'width'},
  {:name => 'archive half legal', :depth => '15.5', :height => '10.25', :width => '2.5', :dimension_units => 'inches', :extent_dimension => 'width'},
  {:name => 'Flat Box', :width => '15', :height => '3', :depth => '18.5', :dimension_units => 'inches', :extent_dimension => 'width'},
  {:name => 'Oversize Folder - half case', :depth => '35.75', :height => '0.15', :width => '23.75', :dimension_units => 'inches', :extent_dimension => 'width'},
  {:name => 'Oversize Folder - full case', :depth => '35.75', :height => '0.15', :width => '48', :dimension_units => 'inches', :extent_dimension => 'width'},
  {:name => 'CD ', :width => '0.4', :height => '4.92', :depth => '5.59', :dimension_units => 'inches', :extent_dimension => 'width'},
  {:name => 'DVD ', :width => '0.55', :height => '7.6', :depth => '5.4', :dimension_units => 'inches', :extent_dimension => 'width'}
]


# Some packings that will mostly fill the different location profile types.
#
# Of the form:
#
#  { 'location profile name' => [packing1, packing2, packing3] }
#
# where each 'packing' is a list of pairs like:
#
#  ['container profile name', number_of_boxes]
#
#
SAMPLE_LOCATION_PROFILE_PACKINGS = {
  "record carton shelf (Remarque)" =>
  [[["archive half legal", 6], ["Paige 15", 1], ["archive legal", 2]],
   [["archive half legal", 15]]],

  "oversize - short - TAM" =>
  [[["Flat Box", 4]]],

  "oversize - short - TAM 2" =>
  [[["Flat Box", 2], ["CD ", 23]]],

  "2 deep - 3 wide - 1 high" =>
  [[["Paige 15", 6]],
   [["archive legal", 4], ["archive letter", 8], ["archive half legal", 6]]],

  "2 deep - 3 wide - 2 high" =>
  [[["Flat Box", 8], ["archive half legal", 12]]],

  "oversize - short" =>
  [[["Oversize Folder - half case", 29]]],

  "cd shelf 1" =>
  [[["CD ", 90]]],

  "cd shelf 2" =>
  [[["DVD ", 42]]],

  "Fales Media Storage 1" =>
  [[["archive letter", 6]]],

  "Fales Media Storage 2" =>
  [[["archive letter", 6]]],

  "map case 2" =>
  [[["Oversize Folder - full case", 9]]],

  "map case 3" =>
  [[["Oversize Folder - half case", 12]]],

  "CSQ standard compact shelf" =>
  [[["Paige 15", 1], ["archive legal", 2]]],

  "CSQ extra high compact shelf with set back" =>
  [[["archive half legal", 11]]],

  "CSQ extra high compact shelf with no set back" =>
  [[["Paige 15", 2]]],

  "UA Shelving (varies)" =>
  [[["archive letter", 7]]],

  "Fales 10W - 2 wide" =>
  [[["Paige 15", 1], ["archive letter", 2]]]}

# Place names
PLACES = java.util.TimeZone.getAvailableIDs.map {|z| z.to_s.split('/')[1]}.compact.reject {|p| p =~ /[A-Z]{3}/}.map {|p| p.sub('_', ' ')}.uniq

# Suffixes
LOCATION_SUFFIXES = ['Square', 'Gardens', 'Library', 'Museum', 'Warehouse', 'Treehouse', 'Bunker']


require 'jsonmodel'
require 'securerandom'

JSONModel::init(:client_mode => true, :url => 'http://localhost:4567')
JSONModel.set_repository(2)

include JSONModel

def login(username, password)
  response = JSONModel::HTTP.post_form(JSONModel(:user).uri_for("#{username}/login"), :password => password)
  JSONModel::HTTP.current_backend_session = ASUtils.json_parse(response.body)['session']
end

def create_location_profiles
  SAMPLE_LOCATION_PROFILES.map do |location|
    p [:creating, location]
    profile_id = JSONModel(:location_profile).from_hash(location).save

    {
      :name => location[:name],
      :uri => JSONModel(:location_profile).uri_for(profile_id)
    }
  end
end

def create_locations(profiles)
  result = []
  combinations = PLACES.flat_map {|place| LOCATION_SUFFIXES.map {|suffix| "#{place} #{suffix}"}}

  raise "Not enough location names" if combinations.length < BUILDING_COUNT

  combinations.shuffle.take(BUILDING_COUNT).each do |building|
    LOCATIONS_PER_BUILDING.times do |i|
      location_profile = profiles.sample
      location_id = JSONModel(:location).from_hash({:building => building,
						    :floor => (i % 2).to_s,
						    :room => (i % 2).to_s,
						    :area => (i % 2).to_s,

						    :coordinate_1_label => 'shelf',
						    :coordinate_1_indicator => i.to_s,

                                                    :barcode => SecureRandom.hex,
                                                    :location_profile => {
                                                      'ref' => location_profile[:uri]
                                                    }
                                                   })
                    .save

      puts "Created location #{building}: #{JSONModel(:location).uri_for(location_id)}"

      result << {
	:location_uri => JSONModel(:location).uri_for(location_id),
	:location_profile => location_profile
      }
    end
  end

  result
end

def create_container_profiles
  result = {}

  SAMPLE_CONTAINER_PROFILES.each do |container_profile|
    container_profile_id = JSONModel(:container_profile).from_hash(container_profile).save

    puts "Created container profile #{container_profile[:name]}: #{JSONModel(:container_profile).uri_for(container_profile_id)}"

    result[container_profile[:name]] = JSONModel(:container_profile).uri_for(container_profile_id)
  end

  result
end

# Generate the appropriate container records for each location of interest
def fill_locations_with_containers(locations, container_profiles)
  locations.each do |location|
    p [:location, location]
    location_profile_name = location[:location_profile][:name]
    packing = SAMPLE_LOCATION_PROFILE_PACKINGS.fetch(location_profile_name).sample

    packing.each do |container_type, count|
      container_profile_uri = container_profiles.fetch(container_type)

      count.times do
        top_container_id = JSONModel(:top_container).from_hash(:indicator => SecureRandom.hex,
                                                               :barcode => SecureRandom.hex,
                                                               :container_profile => {'ref' => container_profile_uri},
                                                               :container_locations => [
                                                                 {'ref' => location[:location_uri],
                                                                  'status' => 'current',
                                                                  'start_date' => '2000-01-01'}
                                                               ]).save

        puts "Created top container with ID: #{top_container_id}"
      end
    end
  end
end


def main(username = 'admin', password = 'admin')
  login(username, password)

  profiles = create_location_profiles
  locations = create_locations(profiles)
  container_profiles = create_container_profiles
  fill_locations_with_containers(locations, container_profiles)
end

main
