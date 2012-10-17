require 'net/http'
require 'json'

class Location < JSONModel(:location)
  attr_accessor :display_string


  def display_string
    return @display_string if @display_string

    @display_string = self.building
    @display_string << ", #{self.floor}" if self.floor
    @display_string << ", #{self.room}" if self.room
    @display_string << ", #{self.area}" if self.area

    others = []
    others << self.barcode if self.barcode
    others << self.classification if self.classification
    others << "#{self.coordinate_1_label}: #{self.coordinate_1_indicator}" if self.coordinate_1_label
    others << "#{self.coordinate_2_label}: #{self.coordinate_2_indicator}" if self.coordinate_2_label
    others << "#{self.coordinate_3_label}: #{self.coordinate_3_indicator}" if self.coordinate_3_label

    @display_string << " [#{others.join(", ")}]"

    @display_string
  end

  def to_hash
    hash = super
    hash["display_string"] = display_string
    hash
  end


end
