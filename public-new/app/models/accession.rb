class Accession < Record

  attr_reader :related_resources

  def initialize(*args)
    super

    @related_resources = parse_related_resources
  end

  def acquisition_type
    if json['acquisition_type']
      I18n.t("enumerations.accession_acquisition_type.#{json['acquisition_type']}", :default => json['acquisition_type'])
    end
  end

  def deaccessions
    ASUtils.wrap(json['deaccessions'])
  end

  private

  def parse_related_resources
    ASUtils.wrap(raw['related_resource_uris']).collect{|uri|
      if raw['_resolved_related_resource_uris']
        raw['_resolved_related_resource_uris'][uri].first
      end
    }.compact.select{|resource|
      resource['publish']
    }.map {|accession|
      record_from_resolved_json(ASUtils.json_parse(accession['json']))
    }
  end
end