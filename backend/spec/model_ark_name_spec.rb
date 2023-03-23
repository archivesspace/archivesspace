require 'spec_helper'

describe 'ArkName model' do

  # turn off those pesky warnings
  # interstingly `around` doesn't work nicely here
  # because it does the around around each enclosed describe block separately
  # and so we get warnings about setting the disable warnings config
  # ... computers!
  before(:all) do
    AppConfig[:disable_config_changed_warning] = true
  end

  after(:all) do
    AppConfig[:disable_config_changed_warning] = false
  end


  describe "with ARKs disabled" do
    before(:each) do
      allow(AppConfig).to receive(:[]).and_call_original
      allow(AppConfig).to receive(:[]).with(:arks_enabled) { false }
    end

    it "does not create ARKs" do
      resource = create_resource
      expect(ArkName.where(:resource_id => resource.id).count).to eq(0)

      archival_object = create_archival_object
      expect(ArkName.where(:archival_object_id => archival_object.id).count).to eq(0)
    end
  end


  describe "with ARKs enabled" do
    before(:each) do
      allow(AppConfig).to receive(:[]).and_call_original
      allow(AppConfig).to receive(:[]).with(:arks_enabled) { true }
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

    it "does not mint an ARK when a resource with a valid ARK is updated" do
      obj = create_resource
      original_ark = ArkName.find(:resource_id => obj.id, :is_current => 1).value

      obj.update_from_json(Resource.to_jsonmodel(obj))

      after_update_ark = ArkName.find(:resource_id => obj.id, :is_current => 1).value

      expect(after_update_ark).to eq(original_ark)
    end

    it "mints an ARK when a resource with an invalid ARK is updated" do
      obj = create_resource
      original_ark = ArkName.find(:resource_id => obj.id, :is_current => 1).value

      ark_naan = AppConfig[:ark_naan]
      AppConfig[:ark_naan] = ark_naan + 'DIFFERENT'

      obj.update_from_json(Resource.to_jsonmodel(obj))

      after_update_ark = ArkName.find(:resource_id => obj.id, :is_current => 1).value

      expect(after_update_ark).to_not eq(original_ark)
      old_arks = ArkName.where(:resource_id => obj.id, :is_current => 0)

      expect(old_arks.count).to eq(1)
      expect(old_arks.first.value).to eq(original_ark)

      AppConfig[:ark_naan] = ark_naan
    end

    it "provides the current ARK and a list of previous ARKs in the json for a record" do
      obj = create_resource
      original_ark = ArkName.find(:resource_id => obj.id, :is_current => 1).value

      ark_naan = AppConfig[:ark_naan]
      AppConfig[:ark_naan] = ark_naan + 'DIFFERENT'
      obj.update_from_json(Resource.to_jsonmodel(obj))

      AppConfig[:ark_naan] = ark_naan + 'VERYDIFFERENT'
      obj = Resource[obj.id]
      obj.update_from_json(Resource.to_jsonmodel(obj))

      json = Resource.to_jsonmodel(obj)

      expect(json.ark_name['current'].class).to eq(String)
      expect(json.ark_name['previous'].length).to eq(2)

      AppConfig[:ark_naan] = ark_naan
    end


    describe('using the ArchivesSpace minter') do
      before(:each) do
        allow(AppConfig).to receive(:[]).with(:ark_minter) { :archivesspace_ark_minter }
      end

      describe('with ARK shoulders disabled') do
        before(:each) do
          allow(AppConfig).to receive(:[]).with(:ark_enable_repository_shoulder) { false }
        end

        it "mints an ARK using the ark_name id and honoring url prefix and naan" do
          obj = create_resource
          ark_obj = ArkName.first(:resource_id => obj.id)

          expect(ark_obj.value).to match(/^#{AppConfig[:ark_url_prefix]}\/ark:\/#{AppConfig[:ark_naan]}\/#{ark_obj.id.to_s}$/)
        end

      end

      describe('with ARK shoulders enabled') do
        before(:each) do
          allow(AppConfig).to receive(:[]).with(:ark_enable_repository_shoulder) { true }
        end

        it "mints an ARK including a shoulder set on the repo" do
          shoulder = 'PADS'
          repo_id = make_test_repo

          Repository[repo_id].update(:ark_shoulder => shoulder)

          RequestContext.open(:repo_id => repo_id) do
            obj = create_resource
            ark = ArkName.first(:resource_id => obj.id).value

            expect(ark).to match(/^#{AppConfig[:ark_url_prefix]}\/ark:\/#{AppConfig[:ark_naan]}\/#{shoulder}/)
          end
        end

        describe('with a shoulder delimiter specified') do
          before(:each) do
            allow(AppConfig).to receive(:[]).with(:ark_shoulder_delimiter) { '---' }
          end

          it "mints an ARK including a shoulder set on the repo" do
            shoulder = 'PADS'
            repo_id = make_test_repo

            Repository[repo_id].update(:ark_shoulder => shoulder)

            RequestContext.open(:repo_id => repo_id) do
              obj = create_resource
              ark = ArkName.first(:resource_id => obj.id).value

              expect(ark).to match(/^#{AppConfig[:ark_url_prefix]}\/ark:\/#{AppConfig[:ark_naan]}\/#{shoulder}#{AppConfig[:ark_shoulder_delimiter]}/)
            end
          end
        end
      end
    end


    describe('using the Smithsonian minter') do
      before(:each) do
        allow(AppConfig).to receive(:[]).with(:ark_minter) { :smithsonian_ark_minter }
      end

      describe('with ARK shoulders disabled') do
        before(:each) do
          allow(AppConfig).to receive(:[]).with(:ark_enable_repository_shoulder) { false }
        end

        it "mints an ARK using a UUID and honoring url prefix and naan" do
          obj = create_resource
          ark = ArkName.first(:resource_id => obj.id).value

          expect(ark).to match(/^#{AppConfig[:ark_url_prefix]}\/ark:\/#{AppConfig[:ark_naan]}\/\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/)
        end
      end

      describe('with ARK shoulders enabled') do
        before(:each) do
          allow(AppConfig).to receive(:[]).with(:ark_enable_repository_shoulder) { true }
        end

        it "mints an ARK including a shoulder set on the repo" do
          shoulder = 'PADS'
          repo_id = make_test_repo

          Repository[repo_id].update(:ark_shoulder => shoulder)

          RequestContext.open(:repo_id => repo_id) do
            obj = create_resource
            ark = ArkName.first(:resource_id => obj.id).value

            expect(ark).to match(/^#{AppConfig[:ark_url_prefix]}\/ark:\/#{AppConfig[:ark_naan]}\/#{shoulder}/)
          end
        end

        describe('with a shoulder delimiter specified') do
          before(:each) do
            allow(AppConfig).to receive(:[]).with(:ark_shoulder_delimiter) { '---' }
          end

          it "mints an ARK including a shoulder set on the repo" do
            shoulder = 'PADS'
            repo_id = make_test_repo

            Repository[repo_id].update(:ark_shoulder => shoulder)

            RequestContext.open(:repo_id => repo_id) do
              obj = create_resource
              ark = ArkName.first(:resource_id => obj.id).value

              expect(ark).to match(/^#{AppConfig[:ark_url_prefix]}\/ark:\/#{AppConfig[:ark_naan]}\/#{shoulder}#{AppConfig[:ark_shoulder_delimiter]}/)
            end
          end
        end
      end
    end


    describe('with external ARKs disabled') do
      before(:each) do
        allow(AppConfig).to receive(:[]).with(:arks_allow_external_arks) { false }
      end

      it "ignores external_ark_url if given" do
        external_ark_url = "http://foo.bar/ark:/123/123"
        obj = create_resource(:external_ark_url => external_ark_url)

        obj = create_resource()
        json = Resource.to_jsonmodel(obj)
        ark = ArkName.first(:resource_id => obj.id).value

        expect(ark).to eq(json['ark_name']['current'])
        expect(ark).to_not eq(external_ark_url)
      end
    end


    describe('with external ARKs enabled') do
      before(:each) do
        allow(AppConfig).to receive(:[]).with(:arks_allow_external_arks) { true }
      end

      it "external_ark_url applies if defined" do
        external_ark_url = "http://foo.bar/ark:/123/123"

        resource = create_resource(:external_ark_url => external_ark_url)

        ark = ArkName.first(:resource_id => resource.id).value

        expect(ark).to eq(external_ark_url)
      end

      it "but an ARK is still generated if external_ark_url is not given" do
        obj = create_resource
        json = Resource.to_jsonmodel(obj)
        ark = ArkName.first(:resource_id => obj.id).value

        expect(ark).to eq(json['ark_name']['current'])
      end

      it "maintains single ARK when external_ark_url is edited" do
        obj = create_resource
        json = Resource.to_jsonmodel(obj)

        # initial ARK
        expect(ArkName.filter(:resource_id => obj.id).count).to eq(1)
        original_generated_ark = ArkName.first(:resource_id => obj.id).value

        # update to external ARK
        external_ark_url = "http://foo.bar/ark:/123/123"
        json['external_ark_url'] = external_ark_url
        Resource[obj.id].update_from_json(json)

        expect(ArkName.filter(:resource_id => obj.id).count).to eq(2)
        expect(ArkName.first(:resource_id => obj.id, :is_current => 1).value).to eq(external_ark_url)

        # set external_ark_url back to empty
        json = Resource.to_jsonmodel(Resource[obj.id])
        json['external_ark_url'] = nil
        Resource[obj.id].update_from_json(json)

        expect(ArkName.filter(:resource_id => obj.id).count).to eq(1)
        expect(ArkName.first(:resource_id => obj.id, :is_current => 1).value).to eq(original_generated_ark)
      end

      it "ensures unique value" do
        external_ark_url = "http://foo.bar/ark:/123/123"

        # give resource A an external_ark_url
        obj_a = create_resource
        json_a = Resource.to_jsonmodel(obj_a)
        json_a['external_ark_url'] = external_ark_url
        Resource[obj_a.id].update_from_json(json_a)

        # try to give resource B the same external_ark_url
        obj_b = create_resource
        json_b = Resource.to_jsonmodel(obj_b)
        json_b['external_ark_url'] = external_ark_url
        expect { Resource[obj_b.id].update_from_json(json_b) }.to raise_error(JSONModel::ValidationException)
      end
    end
  end
end
