class MARCSerializer < ASpaceExport::Serializer
  serializer_for :marc21

  def build(marc, opts = {})
    builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
      _root(marc, xml)
    end

    builder
  end

  # Allow plugins to wrap the MARC record with their own behavior.  Gives them
  # the chance to change the leader, 008, add extra data fields, etc.
  def self.add_decorator(decorator)
    @decorators ||= []
    @decorators << decorator
  end

  def self.decorate_record(record)
    Array(@decorators).reduce(record) {|result, decorator|
      decorator.new(result)
    }
  end


  def serialize(marc, opts = {})
    builder = build(MARCSerializer.decorate_record(marc), opts)

    builder.to_xml
  end


  private

  def _root(marc, xml)
    xml.collection('xmlns'              => 'http://www.loc.gov/MARC21/slim',
                   'xmlns:marc'         => 'http://www.loc.gov/MARC21/slim',
                   'xmlns:xsi'          => 'http://www.w3.org/2001/XMLSchema-instance',
                   'xsi:schemaLocation' => 'http://www.loc.gov/MARC21/slim https://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd') {

      xml.record {

        xml.leader {
          xml.text marc.leader_string
        }

        xml.controlfield(:tag => '008') {
          xml.text marc.controlfield_string
        }
        sorted_datafields = marc.datafields.sort {|a, b| a.tag <=> b.tag}

        sorted_datafields.each do |df|

          df.ind1 = ' ' if df.ind1.nil?
          df.ind2 = ' ' if df.ind2.nil?

          xml.datafield(:tag => df.tag, :ind1 => df.ind1, :ind2 => df.ind2) {

            df.subfields.each do |sf|

              xml.subfield(:code => sf.code) {
                xml.text sf.text.gsub(/<[^>]*>/, ' ')
              }
            end
          }
        end
      }
    }
  end
end
