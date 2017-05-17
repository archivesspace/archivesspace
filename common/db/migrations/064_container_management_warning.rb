require_relative 'utils'

Sequel.migration do

	up do
    
    create_table(:system_event) do
      primary_key :id

      String :title
      DateTime :time, :null => false, :index => true
      String :message

    end

    ## This warning is now disabled because ArchivesSpace 2.1 and above assume
    ## the user has already migrated to the new container model.
    if false
      warning = <<EOF


    #{ "*" * 100 }
    #{ "v" *  42} VERY IMPORTANT #{"v" * 42 } 
    #{ "*" * 100 }
   

    You are updating to a version of ASPACE that has a new container managment model. If you have existing data,
    this will be migrated when you start the application for the first time. The application will not be available 
    until this has completed. 
    PLEASE NOTE : The process wil provide warning and information regarding records that might need to be manually
    fixed. Keep the log from this processes for data cleanup. 
    

    #{ "*" * 100 }
    #{ "^" *  42} VERY IMPORTANT #{"^" * 42 } 
    #{ "*" * 100 }




EOF
      
      $stderr.puts(warning)
    end
  end

  down do
  end

end
