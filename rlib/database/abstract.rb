class AbstractEncDatabase
    
    attr_accessor :engine, :debug
    attr_reader :config, :db, :schema, :user, :password
    attr_reader :strict
    def initialize( engine, conf, debug = false )
        @debug = debug
        @engine = engine
        @config = conf
        
        if( @config.key?( "#{@engine}.db" ) )
            @db = @config.key( "#{@engine}.db" )
        else
            raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: Database not selected."+"\n"
        end
        
    end

    def initdb()
        return nil
    end

    def dropdb()
        return nil
    end

    def terminate( )
        return true
    end
    
    def search( pattern )
        return nil
    end

    def profile( name )
        return nil
    end
    
    def db
        return @config["#{engine}.db"]
    end

end

