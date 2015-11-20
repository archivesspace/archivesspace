require_relative 'utils'

Sequel.migration do

	up do
    warning = <<EOF




    #{ "*" * 100 }
    #{ "!" *  25} VERY IMPORTANT #{"!" * 25 } 
   

    You are updating to a version of ASPACE that has a new container managment model. If you have existing data,
    you will need to migrate it. To do this, change 'AppConfig[:migrate_to_container_management] = true' in your
    config.rb file and start ASPACE. Once this migration process has completed, change the setting back to
    false, and restart ASPACE. 

    If this is a new install and you have no data in your database, you can ignore this step.

    #{ "*" * 100 }




EOF
    
      $stderr.puts(warning)
      sleep(10) 
  end

  down do
  end

end
