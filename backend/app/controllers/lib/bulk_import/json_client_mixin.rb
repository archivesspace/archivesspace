require 'jsonmodel_client'

module ASpaceImportClient

    def self.JSONModel(type)
        super(type)
    end
    def initialize(*args)
        super
    end
    def self.init
        Log.error("CLIENT INIT?")
        if !isInit
            JSONModel::init(:allow_other_unmapped => AppConfig[:allow_other_unmapped], 
                :client_mode => true, :url  => AppConfig[:backend_url])      
        end
    end

    def self.isInit
        begin
            jm = JSONModel.init_args 
            return true
        rescue Exception => e
            Log.error("on initted: #{e.message}")
            return false
        end
    end
end
