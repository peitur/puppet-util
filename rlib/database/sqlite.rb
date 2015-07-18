
require "database/abstract"

################################################################################
class SqliteDatabase < AbstractEncDatabase

    require 'sqlite3'
    
    @@handle = nil
    def initialize( conf, debug )
         super( 'sqlite', conf, debug )
         
         begin
            
            dbname = conf.key?( 'sqlite.db' ) ? conf.key( 'sqlite.db' ) : conf.default( 'sqlite.db' )
            @@handle = SQLite3::Database.new( dbname )
            

            STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Using SQLite based host lookup : "+ @config.key( 'psql.db' ) if( @debug )
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
    
end
