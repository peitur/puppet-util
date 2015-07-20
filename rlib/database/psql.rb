
require "database/abstract"

################################################################################
class PsqlDatabase < AbstractEncDatabase

    require 'pg'
    
    @@handle = nil
    def initialize( conf, debug )
         super( 'psql', conf, debug )
         
         begin
            
            dbname = conf.key?( 'psql.db' ) ? conf.key( 'psql.db' ) : conf.default( 'psql.db' )
            hostname = conf.key?( 'psql.db' ) ? conf.key( 'psql.db' ) : conf.default( 'psql.db' )

            

            STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Using PostgreSQL based host lookup : "+ @config.key( 'psql.db' ) if( @debug )
        rescue => error
            raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: #{error}"+"\n"
        end
        
    end
    
    def terminate( )
        
        if( @@handle and not @@handle.finished?() )
            @@handle.finish()
            return true
        end
        
        return false
    end
    
    def search( pattern )
    
    end
    
    def load_profile( name )
    
    end
    
    def insert( profile, config )
    end
    
    def delete( profile )
    end
    
    def update( profile, config )
    end
    
    def fetch( profile )
    end 
    
end
