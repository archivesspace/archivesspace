class ArchivesSpaceArkMinter < ArkMinter

  def mint!(obj, json, row_defaults)
    DB.open do |db|
      ark_id = db[:ark_name].insert(row_defaults.merge(:user_value => json['external_ark_url']))

      db[:ark_name]
        .filter(:id => ark_id)
        .update(:generated_value => build_generated_ark(ark_id))
    end
  end

  def build_generated_ark(ark_id)
    "ark:/#{AppConfig[:ark_naan]}/#{ark_id}"
  end


  ArkName.register_minter(:archivesspace_ark_minter, self)

end
