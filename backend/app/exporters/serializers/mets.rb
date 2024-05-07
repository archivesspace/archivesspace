class METSSerializer < ASpaceExport::Serializer
  serializer_for :mets

  def build(data, opts = {})
    builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
      if opts[:dmd]
        mets(data, xml, opts[:dmd])
      else
        mets(data, xml)
      end
    end

    builder
  end


  def serialize(data, opts = {})
    builder = build(data, opts)

    builder.to_xml
  end


  private

  def mets(data, xml, dmd = "mods")
    xml.mets('xmlns' => 'http://www.loc.gov/METS/',
             'xmlns:mods' => 'http://www.loc.gov/mods/v3',
             'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
             'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
             'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
             'xsi:schemaLocation' => "http://www.loc.gov/METS/ https://www.loc.gov/standards/mets/mets.xsd") {
      xml.metsHdr(:CREATEDATE => Time.now.iso8601) {
        xml.agent(:ROLE => data.header_agent_role, :TYPE => data.header_agent_type) {
          xml.name data.header_agent_name
          data.header_agent_notes.each do |note|
            xml.note note
          end
        }
      }

      xml.dmdSec(:ID => data.dmd_id) {
        if dmd == 'mods'
          xml.mdWrap(:MDTYPE => 'MODS') {
            xml.xmlData {
              ASpaceExport::Serializer.with_namespace('mods', xml) do
                mods_serializer = ASpaceExport.serializer(:mods).new
                mods_serializer.serialize_mods(data.mods_model, xml)
              end
            }
          }
        elsif dmd == 'dc'
          xml.mdWrap(:MDTYPE => 'DC') {
            xml.xmlData {
              ASpaceExport::Serializer.with_namespace('dc', xml) do
                dc_serializer = ASpaceExport.serializer(:dc).new
                dc_serializer.serialize_dc(data.dc_model, xml)
              end
            }
          }
        end
      }

      data.children.each do |component_data|
        serialize_child_dmd(component_data, xml, dmd)
      end

      xml.amdSec {

      }

      xml.fileSec {
        data.with_file_groups do |file_group|
          xml.fileGrp(:USE => file_group.use) {
            file_group.with_files do |file|
              xml.file(:ID => file.id, :GROUPID => file.group_id) {
                xml.FLocat("xlink:href" => file.uri)
              }
            end
          }
        end
      }

      xml.structMap(:TYPE => 'logical') {
        serialize_logical_div(data.root_logical_div, xml)
      }

      xml.structMap(:TYPE => 'physical') {
        serialize_physical_div(data.root_physical_div, xml)
      }
    }
  end

  def child_files(children, xml)
    children.each do |child|
      if child.file_versions.length
        serialize_files(child.file_versions, xml)
      end
      child_files(child.children, xml)
    end
  end


  def serialize_logical_div(div, xml)
    xml.div(:ORDER => div.order,
            :LABEL => div.label,
            :TYPE => "item",
            :DMDID => div.dmdid
            ) {
      div.each_file_version do |fv|
        xml.fptr(:FILEID => fv.id)
      end
      div.each_child do |child|
        serialize_logical_div(child, xml)
      end
    }
  end


  def serialize_physical_div(div, xml)
    if div.has_files?
      xml.div(:ORDER => div.order,
              :LABEL => div.label,
              :TYPE => "item",
              :DMDID => div.dmdid
              ) {
        div.each_file_version do |fv|
          xml.fptr(:FILEID => fv.id)
        end
        div.each_child do |child|
          serialize_physical_div(child, xml)
        end
      }
    else
      div.each_child do |child|
        serialize_physical_div(child, xml)
      end
    end
  end


  def serialize_files(files, xml)
    @file_id ||= 0
    xml.fileGrp {
      files.each_with_index do |file|
        @file_id += 1
        atts = {'ID' => "f#{@file_id.to_s}"}
        atts.merge({'USE' => file['use_statement']}) if file['use_statement']

        xml.file(atts) {
          xml.FLocat('xlink:href' => file['file_uri'], 'LOCTYPE' => 'URL') {}
        }
      end
    }
  end


  def serialize_child_dmd(component_data, xml, dmd = "mods")
    xml.dmdSec(:ID => component_data.dmd_id) {
      if dmd == 'mods'
        xml.mdWrap(:MDTYPE => 'MODS') {
          xml.xmlData {
            ASpaceExport::Serializer.with_namespace('mods', xml) do
              mods_serializer = ASpaceExport.serializer(:mods).new
              mods_serializer.serialize_mods(component_data.mods_model, xml)
            end
          }
        }
      elsif dmd == 'dc'
        xml.mdWrap(:MDTYPE => 'DC') {
          xml.xmlData {
            ASpaceExport::Serializer.with_namespace('dc', xml) do
              dc_serializer = ASpaceExport.serializer(:dc).new
              dc_serializer.serialize_dc(component_data.dc_model, xml)
            end
          }
        }
      end
    }
    component_data.children.each do |child|
      serialize_child_dmd(child, xml, dmd)
    end
  end

end
