class ArchivesSpaceArkMinter < ArkMinter

  def mint!(obj, row_defaults)
    DB.open do |db|
      # value is not nullable, so put a temporary value in until we put the final
      # value in with the update below.
      ark_id = db[:ark_name].insert(row_defaults.merge(:ark_value => "__ark_placeholder_#{SecureRandom.hex}"))

      ark_shoulder = shoulder_for_repo(obj.repo_id)

      db[:ark_name]
        .filter(:id => ark_id)
        .update(:ark_value => build_generated_ark(ark_id, ark_shoulder))
    end
  end

  # True if the ARK has the right NAAN and has a number that falls within the
  # range that we have already minted.
  def ark_recognized?(ark)
    if ark =~ %r{/ark:/#{AppConfig[:ark_naan]}/.*?(\d+)$}
      ark_number = Integer($1)

      DB.open do |db|
        ark_number <= db[:ark_name].max(:id)
      end
    end
  end

  private

  def build_generated_ark(ark_id, ark_shoulder)
    ark_shoulder_with_delimiter = ''

    if ark_shoulder
      ark_shoulder_with_delimiter = "#{ark_shoulder}#{AppConfig[:ark_shoulder_delimiter]}"
    end

    "ark:/#{AppConfig[:ark_naan]}/#{ark_shoulder_with_delimiter}#{ark_id}"
  end


  ArkName.register_minter(:archivesspace_ark_minter, self)

end
