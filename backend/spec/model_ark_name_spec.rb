require 'spec_helper'

describe 'ArkName model' do

  describe "with ARKs disabled" do
    around(:all) do |all|
      arks_enabled = AppConfig[:arks_enabled]
      AppConfig[:arks_enabled] = false
      all.run
      AppConfig[:arks_enabled] = arks_enabled
    end

    it "does not create ARKs" do
      resource = create_resource
      expect(ArkName.where(:resource_id => resource.id).count).to eq(0)

      archival_object = create_archival_object
      expect(ArkName.where(:archival_object_id => archival_object.id).count).to eq(0)
    end
  end

  describe "with ARKs enabled" do

    around(:all) do |all|
      arks_enabled = AppConfig[:arks_enabled]
      AppConfig[:arks_enabled] = true
      all.run
      AppConfig[:arks_enabled] = arks_enabled
    end

    it "mints an ARK when a resource is created" do
      obj = create_resource
      json = Resource.to_jsonmodel(obj)
      ark = ArkName.first(:resource_id => obj.id).value

      expect(ark).to eq(json['ark_name']['current'])
    end

    it "mints an ARK when an archival object is created" do
      obj = create_archival_object
      json = ArchivalObject.to_jsonmodel(obj)
      ark = ArkName.first(:archival_object_id => obj.id).value

      expect(ark).to eq(json['ark_name']['current'])
    end


    describe('with external ARKs disabled') do
      around(:all) do |all|
        arks_allow_external_arks = AppConfig[:arks_allow_external_arks]
        AppConfig[:arks_allow_external_arks] = false
        all.run
        AppConfig[:arks_allow_external_arks] = arks_allow_external_arks
      end

      it "ignores external_ark_url if given" do
        external_ark_url = "http://foo.bar/ark:/123/123"
        obj = create_resource(external_ark_url: external_ark_url)

        obj = create_resource()
        json = Resource.to_jsonmodel(obj)
        ark = ArkName.first(:resource_id => obj.id).value

        expect(ark).to eq(json['ark_name']['current'])
        expect(ark).to_not eq(external_ark_url)
      end
    end


    describe('with external ARKs enabled') do
      around(:all) do |all|
        arks_allow_external_arks = AppConfig[:arks_allow_external_arks]
        AppConfig[:arks_allow_external_arks] = true
        all.run
        AppConfig[:arks_allow_external_arks] = arks_allow_external_arks
      end

      it "external_ark_url applies if defined" do
        external_ark_url = "http://foo.bar/ark:/123/123"

        resource = create_resource(external_ark_url: external_ark_url)

        ark = ArkName.first(:resource_id => resource.id).value

        expect(ark).to eq(external_ark_url)
      end

      it "but an ARK is still generated if external_ark_url is not given" do
        obj = create_resource
        json = Resource.to_jsonmodel(obj)
        ark = ArkName.first(:resource_id => obj.id).value

        expect(ark).to eq(json['ark_name']['current'])
      end
    end
  end
end
