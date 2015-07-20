
require "database/abstract"
require "fileutils"

################################################################################
class SqliteDatabase < AbstractEncDatabase

	## Pease ensure that the sqlite3 package for ruby is installed
    require 'sqlite3'
    
    @@handle = nil
    def initialize( conf, debug )
         super( 'sqlite', conf, debug )
         
         begin
    		
    		if( not File.exists?( @db ) )
    			initdb()
    		end

            @@handle = SQLite3::Database.open( @db )

            STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Using SQLite based host lookup : "+ @config.key( 'sqlite.db' ) if( @debug )
        rescue => error
            raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: #{error}"+"\n"
        end
        
    end
    
    def terminate( )
        if( @@handle )
            @@handle.close()
            return true
        end
        
        return false
    end
    
    def initdb( )
    	STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Initializing dbschema for sqlite : #{@db}" if( @debug )

    	if( not Dir.exists?( File.dirname( @db ) ) )
	    	STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Creating home directory for sqlite : #{@db}" if( @debug )

    		FileUtils.mkdir_p( File.dirname( @db ) )
    	end

		begin

	    	STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Creating tables for sqlite : #{@db}" if( @debug )

	    	SQLite3::Database.new( @db )
	    	handle = SQLite3::Database.open( @db )
	    
	    	handle.execute( "CREATE TABLE IF NOT EXISTS enc_profiles( id INTEGER PRIMARY KEY, name TEXT, value TEXT, description TEXT )" )
	   		handle.execute( "CREATE TABLE IF NOT EXISTS enc_apply( cert_id INT, profile_id INT, description TEXT )" )
	    	handle.execute( "CREATE TABLE IF NOT EXISTS enc_certs( id INTEGER PRIMARY KEY, name TEXT, description TEXT )" )

	    	handle.close()
    
		rescue SQLite3::Exception => error
		    
            raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: #{error}"+"\n"
		    
		ensure
		   	handle.close if handle
		end

    	return true
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
