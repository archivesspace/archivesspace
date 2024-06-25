require 'spec_helper'

describe 'AS_fop' do
  let(:pdf_image) do
    "file:///" + File.absolute_path(StaticAssetFinder.new(File.join('stylesheets')).find('ArchivesSpaceLogo_for_pdf.png'))
  end

  let(:options) do
    {
      :include_unpublished => false,
      :include_daos => true,
      :use_numbered_c_tags => false
    }
  end

  context 'when converting ead xml to pdf' do
    it 'successfully generates a pdf file' do
      resource = create(:json_resource, title: "Resource Title")
      resource = Resource.get_or_die(resource.id)
      resource_jsonmodel = Resource.to_jsonmodel(resource)

      object = URIResolver.resolve_references(resource_jsonmodel, [
        "repository",
        "linked_agents",
        "subjects",
        "digital_object",
        "top_container",
        "top_container::container_profile"
      ])

      record = JSONModel(:resource).new(object)
      ead = ASpaceExport.model(:ead).from_resource(record, resource.tree(:all, mode = :sparse), options)
      xml = ""
      ASpaceExport.stream(ead).each { |x| xml << x }

      pdf = ASFop.new(xml, pdf_image).to_pdf
      pdf_file = File.read(pdf.path)

      expect(pdf_file).to include "%PDF-1.4"
      expect(pdf_file).to include "Creator (Apache FOP Version 2.5)"
    end
  end

  context 'when testing the FOP output stream as a text file after applying XSLT' do
    before do
      stub_const("MimeConstants::MIME_PDF", MimeConstants::MIME_PLAIN_TEXT)
    end

    context 'when the resource has language material without notes' do
      it 'successfully generates a pdf file' do
        resource = JSONModel(:resource).from_hash(
          {
            "title" => "Resource Title",
            "id_0" => "ABCD",
            "level" => "collection",
            "finding_aid_language" => "eng",
            "finding_aid_script" => "Latn",
            "dates" => [{
              "date_type" => "single",
              "label" => "creation",
              "expression" => "1901",
            }],
            "lang_materials": [
              {
                "language_and_script": {
                  "language": "eng",
                  "script": "Latn"
                }
              },
              {
                "language_and_script": {
                  "language": "aus",
                  "script": "Latn"
                }
              },
              {
                "language_and_script": {
                  "language": "est",
                  "script": "Latn"
                }
              }
            ],
            "extents" => [{
              "portion" => "whole",
              "number" => "5 or so",
              "extent_type" => "reels",
            }]
          }
        )

        resource.save
        resource = Resource.get_or_die(resource.id)
        resource_jsonmodel = Resource.to_jsonmodel(resource)

        object = URIResolver.resolve_references(resource_jsonmodel, [
          "repository",
          "linked_agents",
          "subjects",
          "digital_object",
          "top_container",
          "top_container::container_profile"
        ])

        record = JSONModel(:resource).new(object)
        ead = ASpaceExport.model(:ead).from_resource(record, resource.tree(:all, mode = :sparse), options)
        xml = ""
        ASpaceExport.stream(ead).each { |x| xml << x }

        pdf = ASFop.new(xml, pdf_image).to_pdf
        file = File.read(pdf.path)

        expect(file).to include "Language of the    English, Australian languages, Estonian\r\n                   Material:\r\n\r\n\r\n"
      end
    end

    context 'when the resource has language material notes' do
      now = Time.now.to_i
      let(:language_material_note_a) { "Language Note A #{now}" }
      let(:language_material_note_b) { "Language Note B #{now}" }
      let(:language_material_note_c) { "Language Note C #{now}" }

      it 'successfully applies the ead pdf xsl when renderd as text' do
        resource = JSONModel(:resource).from_hash(
          {
            "title" => "Resource Title",
            "id_0" => "ABCD",
            "level" => "collection",
            "finding_aid_language" => "eng",
            "finding_aid_script" => "Latn",
            "dates" => [{
              "date_type" => "single",
              "label" => "creation",
              "expression" => "1901",
            }],
            "lang_materials": [
              {
                "language_and_script": {
                  "language": "eng",
                  "script": "Latn"
                }
              },
              {
                "notes": [
                  {
                    "jsonmodel_type": "note_langmaterial",
                    "type": "langmaterial",
                    "publish": true,
                    "content": [language_material_note_a]
                  },
                  {
                    "jsonmodel_type": "note_langmaterial",
                    "type": "langmaterial",
                    "publish": true,
                    "content": [language_material_note_b]
                  },
                  {
                    "jsonmodel_type": "note_langmaterial",
                    "type": "langmaterial",
                    "publish": true,
                    "content": [language_material_note_c]
                  },
                ]
              }
            ],
            "extents" => [{
              "portion" => "whole",
              "number" => "5 or so",
              "extent_type" => "reels",
            }]
          }
        )

        resource.save
        resource = Resource.get_or_die(resource.id)
        resource_jsonmodel = Resource.to_jsonmodel(resource)

        object = URIResolver.resolve_references(resource_jsonmodel, [
          "repository",
          "linked_agents",
          "subjects",
          "digital_object",
          "top_container",
          "top_container::container_profile"
        ])

        record = JSONModel(:resource).new(object)
        ead = ASpaceExport.model(:ead).from_resource(record, resource.tree(:all, mode = :sparse), options)
        xml = ""
        ASpaceExport.stream(ead).each { |x| xml << x }

        pdf = ASFop.new(xml, pdf_image).to_pdf
        file = File.read(pdf.path)

        expect(file).to include "Language of the    #{language_material_note_a}\r\n                   Material:\r\n\r\n\r\n\r\n              Language of the    #{language_material_note_b}\r\n        ^ Return to Table of Contents\r\n\r\n\r\n              Language of the    #{language_material_note_c}\r\n                   Material:\r\n        ────────────────────────────────────────────────────────────────────────────────────────\r\n"
      end
    end
  end
end
