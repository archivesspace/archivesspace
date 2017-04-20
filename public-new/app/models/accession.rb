class Accession < Record

  attr_reader :related_resources, :provenance,
              :use_restrictions_note, :access_restrictions_note

  def initialize(*args)
    super

    @related_resources = parse_related_resources
    @use_restrictions_note = json['use_restrictions_note']
    @access_restrictions_note = json['access_restrictions_note']
  end

  def acquisition_type
    if json['acquisition_type']
      I18n.t("enumerations.accession_acquisition_type.#{json['acquisition_type']}", :default => json['acquisition_type'])
    end
  end

  def deaccessions
    ASUtils.wrap(json['deaccessions'])
  end

  def provenance
    json['provenance']
  end

  def restrictions_apply?
    json['restrictions_apply']
  end

  def use_restrictions_note
    json['use_restrictions_note']
  end

  def access_restrictions_note
    json['access_restrictions_note']
  end

  def access_restrictions_apply?
    json['access_restrictions']
  end

  def use_restrictions_apply?
    json['use_restrictions']
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