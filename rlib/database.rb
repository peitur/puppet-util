
require 'util'
require 'config'
################################################################################


################################################################################

require "database/abstract"

################################################################################
## User database interface
class EncDatabase 


    attr_accessor :debug
    attr_reader :db
    def initialize( engine, conf, debug )
        @debug = debug

        begin
            case engine
                when "dir"
                    require "database/dir"
                    @db = DirDatabase.new( conf, debug )
                when "sqlite"
                    require "database/sqlite"
                    @db = SqliteDatabase.new( conf, debug )
                else
                    raise ArgumentError,  "ERROR #{__FILE__}/#{__LINE__}: Requested access engine #{engine} not supported"+"\n"
            end
        rescue => error
            raise ArgumentError,  "ERROR #{__FILE__}/#{__LINE__}: Could not load file for engine #{engine} : #{error}"+"\n"
        end
    end

    def search( pattern )
        
        return nil if( ! @db )
        return nil if( ! pattern )
        
        return @db.search( pattern )
    end
   
    def load_profile( name )
        return nil if( ! @db )
        return nil if( ! name )
        
        return @db.load_profile( name )
    end
   
   
    def insert( profile, config, debug = nil )
        return @db.insert( profile, config )
    end
    
    def delete( what, debug = nil )
        return @db.delete( what )
    end
    
    def update( profile, config, debug = nil )
        return @db.update( profile, config )
    end
    
    def fetch( profile, debug = nil )
        return @db.fetch( profile )
    end
    
    def list( debug = nil )
        return @db.list()
    end
   
    def bind( hostname, profile, debug = nil )
       return @db.bind( hostname, profile )
    end
    
end
