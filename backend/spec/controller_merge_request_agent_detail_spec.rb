require 'spec_helper'

describe 'Merge request agent detail' do
  def get_merge_request_detail_json(merge_destination, merge_candidate, selections)
    request = JSONModel(:merge_request_detail).new
    request.merge_destination = {'ref' => merge_destination.uri}
    request.merge_candidates = [{'ref' => merge_candidate.uri}]
    request.selections = selections

    return request
  end

  # In the tests below, selection hash order will determine which subrec in merge_destination is replaced
  # For example, in a replace operation the contents of selection[n] will replace merge_destination[subrecord][n]
  # Some of these tests simulate a replacement of selection[0] to merge_destination[subrecord][0]
  # Others simulate selection[1] to merge_destination[subrecord][1]

  it "can replace entire subrecord on merge" do
    merge_destination = create(:json_agent_person_merge_destination)
    merge_candidate = create(:json_agent_person_merge_candidate)
    subrecord = merge_candidate["agent_conventions_declarations"][0]

    selections = {
      'agent_conventions_declarations' => [
        {
          'replace' => "REPLACE",
          'position' => "0"
        }
      ]
    }

    merge_request = get_merge_request_detail_json(merge_destination, merge_candidate, selections)
    merge_request.save(:record_type => 'agent_detail')

    merge_destination_record = JSONModel(:agent_person).find(merge_destination.id)
    replaced_subrecord = merge_destination_record['agent_conventions_declarations'][0]

    replaced_subrecord.each_key do |k|
      next if k == "id" || k == "agent_person_id" || k =~ /time/
      expect(replaced_subrecord[k]).to eq(subrecord[k])
    end

    expect {
      JSONModel(:agent_person).find(merge_candidate.id)
    }.to raise_error(RecordNotFound)
  end

  it "can append entire subrecord on merge" do
    merge_destination = create(:json_agent_person_merge_destination)
    merge_candidate = create(:json_agent_person_merge_candidate)
    subrecord = merge_candidate["agent_conventions_declarations"][0]
    merge_destination_subrecord_count = merge_destination['agent_conventions_declarations'].length

    selections = {
      'agent_conventions_declarations' => [
        {
          'append' => "REPLACE",
          'position' => "0"
        },
      ]
    }

    merge_request = get_merge_request_detail_json(merge_destination, merge_candidate, selections)
    merge_request.save(:record_type => 'agent_detail')

    merge_destination_record = JSONModel(:agent_person).find(merge_destination.id)
    appended_subrecord = merge_destination_record['agent_conventions_declarations'].last

    expect(merge_destination_record['agent_conventions_declarations'].length).to eq(merge_destination_subrecord_count += 1)

    appended_subrecord.each_key do |k|
      next if k == "id" || k == "agent_person_id" || k =~ /time/
      expect(appended_subrecord[k]).to eq(subrecord[k])
    end

    expect {
      JSONModel(:agent_person).find(merge_candidate.id)
    }.to raise_error(RecordNotFound)
  end

  it "can replace field in subrecord on merge" do
    merge_destination = create(:json_agent_person_merge_destination)
    merge_candidate = create(:json_agent_person_merge_candidate)
    merge_destination_subrecord = merge_destination["agent_record_controls"][0]
    merge_candidate_subrecord = merge_candidate["agent_record_controls"][0]

    selections = {
      'agent_record_controls' => [
        {
          'maintenance_agency' => "REPLACE",
          'position' => "0"
        }
      ]
    }

    merge_request = get_merge_request_detail_json(merge_destination, merge_candidate, selections)
    merge_request.save(:record_type => 'agent_detail')

    merge_destination_record = JSONModel(:agent_person).find(merge_destination.id)
    replaced_subrecord = merge_destination_record['agent_record_controls'][0]

    # replaced field
    expect(replaced_subrecord['maintenance_agency']).to eq(merge_candidate_subrecord['maintenance_agency'])

    # other fields in subrec should stay the same as before
    replaced_subrecord.each_key do |k|
      next if k == "id" || k == "maintenance_agency" || k =~ /time/
      expect(replaced_subrecord[k]).to eq(merge_destination_subrecord[k])
    end

    expect {
      JSONModel(:agent_person).find(merge_candidate.id)
    }.to raise_error(RecordNotFound)
  end

  it "can replace entire subrecord on merge when order is changed" do
    merge_destination = create(:json_agent_person_merge_destination)
    merge_candidate = create(:json_agent_person_merge_candidate)
    subrecord = merge_candidate["agent_conventions_declarations"][0]


    selections = {
      'agent_conventions_declarations' => [
        {
          'position' => "1"
        },
        {
          'replace' => "REPLACE",
          'position' => "0"
        }
      ]
    }

    merge_request = get_merge_request_detail_json(merge_destination, merge_candidate, selections)
    merge_request.save(:record_type => 'agent_detail')

    merge_destination_record = JSONModel(:agent_person).find(merge_destination.id)
    replaced_subrecord = merge_destination_record['agent_conventions_declarations'][1]

    replaced_subrecord.each_key do |k|
      next if k == "id" || k == "agent_person_id" || k =~ /time/
      expect(replaced_subrecord[k]).to eq(subrecord[k])
    end

    expect {
      JSONModel(:agent_person).find(merge_candidate.id)
    }.to raise_error(RecordNotFound)
  end

  it "can append entire subrecord on merge when order is changed" do
    merge_destination = create(:json_agent_person_merge_destination)
    merge_candidate = create(:json_agent_person_merge_candidate)
    subrecord = merge_candidate["agent_conventions_declarations"][0]
    merge_destination_subrecord_count = merge_destination['agent_conventions_declarations'].length

    selections = {
      'agent_conventions_declarations' => [
        {
          'position' => "1"
        },
        {
          'append' => "REPLACE",
          'position' => "0"
        },
      ]
    }

    merge_request = get_merge_request_detail_json(merge_destination, merge_candidate, selections)
    merge_request.save(:record_type => 'agent_detail')

    merge_destination_record = JSONModel(:agent_person).find(merge_destination.id)
    appended_subrecord = merge_destination_record['agent_conventions_declarations'].last

    expect(merge_destination_record['agent_conventions_declarations'].length).to eq(merge_destination_subrecord_count += 1)

    appended_subrecord.each_key do |k|
      next if k == "id" || k == "agent_person_id" || k =~ /time/
      expect(appended_subrecord[k]).to eq(subrecord[k])
    end

    expect {
      JSONModel(:agent_person).find(merge_candidate.id)
    }.to raise_error(RecordNotFound)
  end

  it "can replace field in subrecord on merge when order is changed" do
    merge_destination = create(:json_agent_person_merge_destination)
    merge_candidate = create(:json_agent_person_merge_candidate)
    merge_destination_subrecord = merge_destination["agent_conventions_declarations"][1]
    merge_candidate_subrecord = merge_candidate["agent_conventions_declarations"][0]

    selections = {
      'agent_conventions_declarations' => [
        {
          'position' => "1"
        },
        {
          'descriptive_note' => "REPLACE",
          'position' => "0"
        }
      ]
    }

    merge_request = get_merge_request_detail_json(merge_destination, merge_candidate, selections)
    merge_request.save(:record_type => 'agent_detail')

    merge_destination_record = JSONModel(:agent_person).find(merge_destination.id)
    replaced_subrecord = merge_destination_record['agent_conventions_declarations'][1]

    # replaced field
    expect(replaced_subrecord['descriptive_note']).to eq(merge_candidate_subrecord['descriptive_note'])

    # other fields in subrec should stay the same as before
    replaced_subrecord.each_key do |k|
      next if k == "id" || k == "descriptive_note" || k =~ /time/
      expect(replaced_subrecord[k]).to eq(merge_destination_subrecord[k])
    end

    expect {
      JSONModel(:agent_person).find(merge_candidate.id)
    }.to raise_error(RecordNotFound)
  end
end
