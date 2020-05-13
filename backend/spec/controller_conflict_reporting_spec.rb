require 'spec_helper'

describe "Conflicting record handling" do

  describe "Subjects" do
    before(:each) do
      vocab = JSONModel(:vocabulary).from_hash("name" => "Cool Vocab",
                                               "ref_id" => "coolid"
                                              )
      vocab.save
      @vocab_id = vocab.id
    end

    let (:subject_properties) do
      {
        :terms => [build(:json_term, "term" => "1981 Heroes")],
        :vocabulary => JSONModel(:vocabulary).uri_for(@vocab_id),
        :source => "local"
      }
    end

    it "reports conflicting records on create" do
      subject = create(:json_subject, subject_properties)

      exception = begin
                    create(:json_subject, subject_properties)
                    nil
                  rescue JSONModel::ValidationException => e
                    e
                  end

      expect(exception).not_to be_nil
      expect(exception.errors['conflicting_record']).to eq([subject.uri])
    end


    it "reports conflicting records on update" do
      subject_a = create(:json_subject, subject_properties)
      subject_b = create(:json_subject, subject_properties.merge(:terms => [build(:json_term, "term" => "Non-conflicting")]))

      exception = begin
                    subject_b[:terms] = subject_properties[:terms]
                    subject_b.save
                    nil
                  rescue JSONModel::ValidationException => e
                    e
                  end

      expect(exception).not_to be_nil
      expect(exception.errors['conflicting_record']).to eq([subject_a.uri])
    end


    it "reports conflicting record authority ids on update" do
      subject_a = create(:json_subject, subject_properties)
      subject_b = create(:json_subject, subject_properties.merge(:terms => [build(:json_term, "term" => "Non-conflicting")]))

      exception = begin
                    subject_b['authority_id'] = subject_a['authority_id']
                    subject_b.save
                    nil
                  rescue JSONModel::ValidationException => e
                    e
                  end

      expect(exception).not_to be_nil
    end
  end


  describe "Agents" do
    before(:each) do
    end

    let (:subject_properties) do
      {
        :terms => [build(:json_term, "term" => "1981 Heroes")],
        :vocabulary => JSONModel(:vocabulary).uri_for(@vocab_id),
        :source => "local"
      }
    end

    it "reports conflicting records on create" do
      AgentManager.registered_agents.each do |agent_type|
        jsonmodel = agent_type.fetch(:jsonmodel)
        agent_a = build(:"json_#{jsonmodel}")
        agent_b = build(:"json_#{jsonmodel}", agent_a.to_hash)

        agent_a.save

        exception = begin
                      agent_b.save
                      nil
                    rescue JSONModel::ValidationException => e
                      e
                    end

        expect(exception).not_to be_nil
        expect(exception.errors['conflicting_record']).to eq([agent_a.uri])
      end
    end


    it "reports conflicting records on update" do
      AgentManager.registered_agents.each do |agent_type|
        jsonmodel = agent_type.fetch(:jsonmodel)
        agent_archetype = build(:"json_#{jsonmodel}")
        agent_a = create(:"json_#{jsonmodel}", agent_archetype.to_hash)
        agent_b = create(:"json_#{jsonmodel}", agent_archetype.to_hash.merge('names' => build(:"json_#{jsonmodel}")[:names]))

        exception = begin
                      agent_b[:names] = agent_archetype[:names]
                      agent_b.save
                      nil
                    rescue JSONModel::ValidationException => e
                      e
                    end

        expect(exception).not_to be_nil, "No exception on update for #{agent_type}"
        expect(exception.errors['conflicting_record']).to eq([agent_a.uri])
      end
    end


    it "reports conflicting record authority ids on update" do
      AgentManager.registered_agents.each do |agent_type|
        jsonmodel = agent_type.fetch(:jsonmodel)
        agent_archetype = build(:"json_#{jsonmodel}")
        agent_a = create(:"json_#{jsonmodel}", agent_archetype.to_hash)
        agent_b = create(:"json_#{jsonmodel}", agent_archetype.to_hash.merge('names' => build(:"json_#{jsonmodel}")[:names]))

        exception = begin
                      agent_b[:names][0]['authority_id'] = agent_archetype[:names][0]['authority_id']
                      agent_b.save
                      nil
                    rescue JSONModel::ValidationException => e
                      e
                    end

        expect(exception).not_to be_nil, "No exception on update for #{agent_type}"
        expect(exception.errors['conflicting_record']).to eq([agent_a.uri])
      end
    end

  end


end
