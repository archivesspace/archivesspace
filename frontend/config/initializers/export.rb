if ENV['DISABLE_STARTUP'] != 'true'

  ead_dir = Rails.root.join('tmp', 'ead')

  unless FileTest::directory?(ead_dir)
    Dir::mkdir(ead_dir)
  end
end