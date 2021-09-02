class ArchivesSpaceArkMinter < ArkMinter

  def mint!(obj, external_ark_url, row_defaults)
    DB.open do |db|
      ark_id = db[:ark_name].insert(row_defaults.merge(:user_value => external_ark_url,
                                                       :version_key => generate_version_key(obj.repo_id)))

      ark_shoulder = shoulder_for_repo(obj.repo_id)

      db[:ark_name]
        .filter(:id => ark_id)
        .update(:generated_value => build_generated_ark(ark_id, ark_shoulder))
    end
  end

  def is_still_current?(ark_name_obj, repo_id)
    ark_name_obj.version_key == generate_version_key(repo_id)
  end

  private

  def generate_version_key(repo_id)
    ArkMinter.generate_version_key(AppConfig[:ark_naan], shoulder_for_repo(repo_id), AppConfig[:ark_shoulder_delimiter])
  end

  def build_generated_ark(ark_id, ark_shoulder)
    ark_shoulder_with_delimiter = ''

    if ark_shoulder
      ark_shoulder_with_delimiter = "#{ark_shoulder}#{AppConfig[:ark_shoulder_delimiter]}"
    end

    "ark:/#{AppConfig[:ark_naan]}/#{ark_shoulder_with_delimiter}#{ark_id}"
  end


  ArkName.register_minter(:archivesspace_ark_minter, self)

end
