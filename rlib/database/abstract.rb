class AbstractEncDatabase
    
    @@profile_table = "enc_profiles"
    @@host_table = "enc_hosts"

    @@profile_id = "id"
    @@profile_name = "name"
    @@profile_value = "value"

    @@host_id = "id"    
    @@host_host = "host"
    @@host_profile_id = "profile_id"
        
    attr_accessor :engine, :debug
    attr_reader :config, :db, :hostname, :schema, :user, :password
    attr_reader :strict
    def initialize( engine, conf, debug = false )
        @debug = debug
        @engine = engine
        @config = conf
        
        @db = conf.key?( "#{@engine}.db" ) ? conf.key( "#{@engine}.db" ) : conf.default( "#{@engine}.db" )
        @hostname = conf.key?( "#{@engine}.hostname" ) ? conf.key( "#{@engine}.hostname" ) : conf.default( "#{@engine}.hostname" )
        @user = conf.key?( "#{@engine}.user" ) ? conf.key( "#{@engine}.user" ) : conf.default( "#{@engine}.user" )
        @password = conf.key?( "#{@engine}.password" ) ? conf.key( "#{@engine}.password" ) : conf.default( "#{@engine}.password" )
        @schema = conf.key?( "#{@engine}.schema" ) ? conf.key( "#{@engine}.schema" ) : conf.default( "#{@engine}.schema" )

        if( @config.key?( "#{@engine}.db" ) )
            @db = @config.key( "#{@engine}.db" )
        else
            raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: Database not selected."+"\n"
        end
        
    end

    def dropdb()
        
        return true
    end


    
end

