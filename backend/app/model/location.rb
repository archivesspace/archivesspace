class Location < Sequel::Model(:location)
  include ASModel
  corresponds_to JSONModel(:location)

  include ExternalIDs
  include AutoGenerator

  set_model_scope :repository

  auto_generate :property => :title,
                :generator => proc  { |json|
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
                }

  def self.create_for_batch(batch)
    indicators_1, indicators_2, indicators_3  = [batch["coordinate_1"], batch["coordinate_2"], batch["coordinate_3"]].
                                                  compact.
                                                  map{|data| generate_indicators(data)}

    source_location = batch["source_location"]

    results = []

    indicators_1.each do |indicator_1|
      source_location["coordinate_1_label"] = batch["coordinate_1"]["label"]
      source_location["coordinate_1_indicator"] = indicator_1

      if indicators_2
        indicators_2.each do |indicator_2|
          source_location["coordinate_2_label"] = batch["coordinate_2"]["label"]
          source_location["coordinate_2_indicator"] = indicator_2

          if indicators_3
            indicators_3.each do |indicator_3|
              source_location["coordinate_3_label"] = batch["coordinate_3"]["label"]
              source_location["coordinate_3_indicator"] = indicator_3

              results.push(self.create_from_json(JSONModel(:location).from_hash(source_location)))
            end
          else
            results.push(self.create_from_json(JSONModel(:location).from_hash(source_location)))
          end
        end
      else
        results.push(self.create_from_json(JSONModel(:location).from_hash(source_location)))
      end
    end

    results
  end

  def self.generate_indicators(opts)
    (opts["start"]..opts["end"]).map{|i| "#{opts["prefix"]}#{i}#{opts["suffix"]}"}
  end

end
