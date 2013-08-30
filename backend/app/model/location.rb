class Location < Sequel::Model(:location)
  include ASModel
  corresponds_to JSONModel(:location)

  include ExternalIDs
  include AutoGenerator

  set_model_scope :global

  def self.generate_title(json)
    title = ""

    title << json['building']
    title << ", #{json['floor']}" if json['floor']
    title << ", #{json['room']}" if json['room']
    title << ", #{json['area']}" if json['area']

    others = []
    others << json['barcode'] if json['barcode']
    others << json['classification'] if json['classification']
    others << "#{json['coordinate_1_label']}: #{json['coordinate_1_indicator']}" if json['coordinate_1_label']
    others << "#{json['coordinate_2_label']}: #{json['coordinate_2_indicator']}" if json['coordinate_2_label']
    others << "#{json['coordinate_3_label']}: #{json['coordinate_3_indicator']}" if json['coordinate_3_label']

    title << " [#{others.join(", ")}]"

    title
  end

  auto_generate :property => :title,
                :generator => proc {|json|
                  Location.generate_title(json)
                }


  def self.create_for_batch(batch)
    locations = generate_locations_for_batch(batch)
    locations.map{|location| self.create_from_json(location)}
  end

  def self.titles_for_batch(batch)
    locations = generate_locations_for_batch(batch)
    locations.map{|location| self.generate_title(location)}
  end

  def self.generate_locations_for_batch(batch)
    indicators_1, indicators_2, indicators_3  = [batch["coordinate_1_range"], batch["coordinate_2_range"], batch["coordinate_3_range"]].
                                                  compact.
                                                  map{|data| generate_indicators(data)}

    source_location = batch.clone

    results = []

    indicators_1.each do |indicator_1|
      source_location["coordinate_1_label"] = batch["coordinate_1_range"]["label"]
      source_location["coordinate_1_indicator"] = indicator_1

      if indicators_2
        indicators_2.each do |indicator_2|
          source_location["coordinate_2_label"] = batch["coordinate_2_range"]["label"]
          source_location["coordinate_2_indicator"] = indicator_2

          if indicators_3
            indicators_3.each do |indicator_3|
              source_location["coordinate_3_label"] = batch["coordinate_3_range"]["label"]
              source_location["coordinate_3_indicator"] = indicator_3

              results.push(JSONModel(:location).from_hash(source_location))
            end
          else
            results.push(JSONModel(:location).from_hash(source_location))
          end
        end
      else
        results.push(JSONModel(:location).from_hash(source_location))
      end
    end

    results
  end

  def self.generate_indicators(opts)
    (opts["start"]..opts["end"]).map{|i| "#{opts["prefix"]}#{i}#{opts["suffix"]}"}
  end

end
