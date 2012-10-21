require 'net/http'
require 'json'

class Location < JSONModel(:location)
  attr_accessor :display_string


  def display_string
    return @display_string if @display_string

    @display_string = ""

    @display_string << "[#{I18n.t("location.temporary_#{self.temporary}")}] " if not self.temporary.blank?

    @display_string << self.building
    @display_string << ", #{self.floor}" if self.floor
    @display_string << ", #{self.room}" if self.room
    @display_string << ", #{self.area}" if self.area

    others = []
    others << self.barcode if not self.barcode.blank?
    others << self.classification if not self.classification.blank?
    others << "#{self.coordinate_1_label}: #{self.coordinate_1_indicator}" if not self.coordinate_1_label.blank?
    others << "#{self.coordinate_2_label}: #{self.coordinate_2_indicator}" if not self.coordinate_2_label.blank?
    others << "#{self.coordinate_3_label}: #{self.coordinate_3_indicator}" if not self.coordinate_3_label.blank?

    @display_string << " [#{others.join(", ")}]"

    @display_string
  end

  def to_hash
    hash = super
    hash["display_string"] = display_string
    hash
  end


end
